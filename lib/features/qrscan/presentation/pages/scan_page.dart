import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, HapticFeedback;
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/location_helper.dart';
import '../../domain/entities/scan.dart';
import '../providers/qrscan_provider.dart';
import '../widgets/qr_data_display.dart';
import '../widgets/scan_details_dialog.dart';

/// Full-screen camera that reads QR codes, opened from the Scans list's
/// Scan button. Pinch / slider / double-tap zoom, torch and camera switch.
/// The camera is released when the page closes; MobileScanner also pauses
/// it while the app is in the background.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  MobileScannerController? _controller;
  bool _handling = false;
  double _pinchBase = 0;

  @override
  void initState() {
    super.initState();
    _controller = _newController();
  }

  MobileScannerController _newController() =>
      MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ── Zoom ──────────────────────────────────────────────────────────────────

  Future<void> _zoomTo(double value) async {
    final c = _controller;
    if (c == null || !c.value.isRunning) return;
    await c.setZoomScale(value.clamp(0.0, 1.0));
  }

  // ── Detection ─────────────────────────────────────────────────────────────

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    String? data;
    for (final b in capture.barcodes) {
      final v = b.rawValue ?? b.displayValue;
      if (v != null && v.trim().isNotEmpty) {
        data = v;
        break;
      }
    }
    if (data == null) return;

    _handling = true;
    final settings = context.read<SettingsProvider>();
    if (settings.vibrate) HapticFeedback.mediumImpact();
    await _controller?.pause(); // freeze the frame behind the result

    if (!mounted) return;
    // Mark the future handled: if location fails before the sheet listens,
    // the error would otherwise be reported as uncaught. The sheet still
    // receives and shows it.
    final saving =
        (settings.saveScans
              ? _save(data, withLocation: settings.saveLocation)
              : Future<Scan?>.value(null))
          ..ignore();
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ScanResultSheet(data: data!, saving: saving),
    );

    _handling = false;
    if (!mounted) return;
    if (action == 'done') {
      Navigator.of(context).pop(); // back to the Scans list
    } else {
      await _controller?.start();
    }
  }

  /// Saves the scan to the Scans list, with the current location unless the
  /// user turned that off in Settings.
  Future<Scan?> _save(String data, {required bool withLocation}) async {
    final provider = context.read<QrScanProvider>();
    provider.setProcessingScan(true);
    try {
      final (lat, lng, address) = withLocation
          ? await LocationHelper.getCurrentLocation()
          : (0.0, 0.0, Scan.noLocation);
      final scan = Scan(
        qrData: data,
        timestamp: DateTime.now(),
        latitude: lat,
        longitude: lng,
        address: address,
      );
      await provider.addScan(scan);
      return scan;
    } finally {
      provider.setProcessingScan(false);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const ColoredBox(color: Colors.black);

    final latest = context.select<QrScanProvider, Scan?>(
      (p) => p.scans.isEmpty ? null : p.scans.first,
    );
    final insets = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan a code'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(
              error: error,
              onRetry: () async {
                await controller.stop();
                await controller.start();
              },
            ),
          ),
          // Pinch to zoom, double-tap to jump between 1x and 2x-ish.
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: (_) => _pinchBase = controller.value.zoomScale,
            onScaleUpdate: (d) {
              if (d.pointerCount < 2) return;
              _zoomTo(_pinchBase + (d.scale - 1) * 0.5);
            },
            onDoubleTap: () =>
                _zoomTo(controller.value.zoomScale > 0.2 ? 0 : 0.4),
          ),
          const IgnorePointer(child: _ScanFrame()),
          // Top controls: torch + camera switch.
          Positioned(
            top: insets.top + kToolbarHeight + 16,
            right: 16,
            child: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, _) => Column(
                children: [
                  if (state.torchState != TorchState.unavailable)
                    _RoundButton(
                      icon: state.torchState == TorchState.on
                          ? Icons.flash_on
                          : Icons.flash_off,
                      tooltip: state.torchState == TorchState.on
                          ? 'Turn flashlight off'
                          : 'Turn flashlight on',
                      active: state.torchState == TorchState.on,
                      onTap: state.isRunning ? controller.toggleTorch : null,
                    ),
                  const SizedBox(height: 12),
                  _RoundButton(
                    icon: Icons.cameraswitch_outlined,
                    tooltip: 'Switch camera',
                    onTap: state.isRunning ? controller.switchCamera : null,
                  ),
                ],
              ),
            ),
          ),
          // Bottom: last scan + zoom controls.
          Positioned(
            left: 16,
            right: 16,
            bottom: insets.bottom + 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (latest != null) ...[
                      _LastScanPill(
                        scan: latest,
                        onTap: () => ScanDetailsDialog.show(
                          context: context,
                          scan: latest,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: controller,
                      builder: (context, state, _) => _ZoomBar(
                        value: state.zoomScale.clamp(0.0, 1.0),
                        enabled: state.isRunning,
                        onChanged: _zoomTo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dims everything outside a centered square and draws orange corners.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final side = (box.biggest.shortestSide * 0.62).clamp(160.0, 320.0);
        // Sit a little above center to leave room for the bottom controls.
        final center = Offset(box.maxWidth / 2, box.maxHeight * 0.42);
        final rect = Rect.fromCenter(center: center, width: side, height: side);
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FramePainter(
                  rect,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: rect.top - 44,
              child: Text(
                'Point the camera at a QR code',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FramePainter extends CustomPainter {
  final Rect rect;
  final Color color;
  _FramePainter(this.rect, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    final dim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = const Color(0x8C000000));

    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const len = 34.0;
    const r = 20.0;
    final l = rect.left, t = rect.top, rt = rect.right, b = rect.bottom;
    for (final path in [
      Path()
        ..moveTo(l, t + len)
        ..lineTo(l, t + r)
        ..arcToPoint(Offset(l + r, t), radius: const Radius.circular(r))
        ..lineTo(l + len, t),
      Path()
        ..moveTo(rt - len, t)
        ..lineTo(rt - r, t)
        ..arcToPoint(Offset(rt, t + r), radius: const Radius.circular(r))
        ..lineTo(rt, t + len),
      Path()
        ..moveTo(rt, b - len)
        ..lineTo(rt, b - r)
        ..arcToPoint(Offset(rt - r, b), radius: const Radius.circular(r))
        ..lineTo(rt - len, b),
      Path()
        ..moveTo(l + len, b)
        ..lineTo(l + r, b)
        ..arcToPoint(Offset(l, b - r), radius: const Radius.circular(r))
        ..lineTo(l, b - len),
    ]) {
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.rect != rect || old.color != color;
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;

  const _RoundButton({
    required this.icon,
    required this.tooltip,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? primary : Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

class _ZoomBar extends StatelessWidget {
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _ZoomBar({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Zoom out',
            color: Colors.white,
            onPressed: enabled && value > 0
                ? () => onChanged(value - 0.1)
                : null,
            icon: const Icon(Icons.zoom_out),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: primary,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: primary.withValues(alpha: 0.2),
                trackHeight: 3,
              ),
              child: Slider(
                value: value,
                onChanged: enabled ? onChanged : null,
                semanticFormatterCallback: (v) => 'Zoom ${(v * 100).round()}%',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Zoom in',
            color: Colors.white,
            onPressed: enabled && value < 1
                ? () => onChanged(value + 0.1)
                : null,
            icon: const Icon(Icons.zoom_in),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${(value * 100).round()}%',
              textAlign: TextAlign.center,
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastScanPill extends StatelessWidget {
  final Scan scan;
  final VoidCallback onTap;

  const _LastScanPill({required this.scan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'Last:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  scan.qrData,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onRetry;

  const _CameraError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                denied ? Icons.no_photography_outlined : Icons.error_outline,
                color: Colors.white70,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                denied ? 'Camera access is off' : 'The camera couldn\'t start',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                denied
                    ? 'Allow camera access for Locus to scan QR codes.'
                    : (error.errorDetails?.message ?? error.errorCode.name),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (denied)
                    FilledButton.icon(
                      onPressed: Geolocator.openAppSettings,
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('Open settings'),
                    ),
                  OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown after a code is read: what it contains, whether it was saved, and
/// what to do next. [saving] completes when the scan is saved.
class ScanResultSheet extends StatelessWidget {
  final String data;

  /// Completes with the saved scan, or null when saving is off in Settings.
  final Future<Scan?> saving;

  const ScanResultSheet({super.key, required this.data, required this.saving});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code_2, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Code scanned',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: data));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: QRDataDisplay(qrData: data),
              ),
              const SizedBox(height: 12),
              FutureBuilder<Scan?>(
                future: saving,
                builder: (context, snap) {
                  final (icon, color, text) = switch (snap.connectionState) {
                    ConnectionState.done when snap.hasError => (
                      Icons.error_outline,
                      colorScheme.error,
                      'Not saved: ${_reason(snap.error)}',
                    ),
                    ConnectionState.done when snap.data == null => (
                      Icons.visibility_outlined,
                      colorScheme.onSurfaceVariant,
                      'Not saved — saving scans is off in Settings',
                    ),
                    ConnectionState.done => (
                      Icons.check_circle,
                      colorScheme.primary,
                      snap.data!.hasLocation
                          ? 'Saved to Scans · ${snap.data!.address}'
                          : 'Saved to Scans (without location)',
                    ),
                    _ => (
                      Icons.location_searching,
                      colorScheme.onSurfaceVariant,
                      'Saving…',
                    ),
                  };
                  return Row(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: textTheme.bodySmall?.copyWith(color: color),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, 'done'),
                      icon: const Icon(Icons.check),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Done', maxLines: 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, 'again'),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Scan again', maxLines: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _reason(Object? e) {
    final s = e.toString().replaceFirst('Exception: ', '');
    return s.isEmpty ? 'unknown error' : s;
  }
}
