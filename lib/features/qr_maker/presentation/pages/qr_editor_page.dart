import 'dart:convert';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/created_code.dart';
import '../../domain/entities/qr_style.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/qr_encoder.dart';
import '../providers/qr_maker_provider.dart';
import '../utils/qr_export.dart';
import '../widgets/styled_qr.dart';

/// Form + live preview for making one QR code, with style options and
/// save / gallery / share actions.
class QrEditorPage extends StatefulWidget {
  final QrType type;
  final CreatedCode? existing;

  const QrEditorPage({super.key, required this.type}) : existing = null;

  QrEditorPage.edit({super.key, required CreatedCode code})
    : type = code.type,
      existing = code;

  @override
  State<QrEditorPage> createState() => _QrEditorPageState();
}

class _QrEditorPageState extends State<QrEditorPage> {
  final _previewKey = GlobalKey();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _optionValues = {}; // choice + toggle fields
  final Set<String> _revealed = {};
  late final TextEditingController _captionController;
  late QrStyle _style;
  CreatedCode? _saved;
  bool _busy = false;

  QrType get _type => widget.type;

  @override
  void initState() {
    super.initState();
    final initial = {..._type.initialValues, ...?widget.existing?.fields};
    for (final f in _type.fields) {
      if (f.kind == QrFieldKind.choice || f.kind == QrFieldKind.toggle) {
        _optionValues[f.key] = initial[f.key] ?? '';
      } else {
        _controllers[f.key] = TextEditingController(text: initial[f.key])
          ..addListener(_refresh);
      }
    }
    _style = widget.existing?.style ?? const QrStyle();
    _captionController = TextEditingController(text: _style.caption)
      ..addListener(() {
        setState(
          () => _style = _style.copyWith(caption: _captionController.text),
        );
      });
    _saved = widget.existing;
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _captionController.dispose();
    super.dispose();
  }

  Map<String, String> get _values => {
    for (final e in _controllers.entries) e.key: e.value.text,
    ..._optionValues,
  };

  bool _isUnchanged(Map<String, String> values) =>
      _saved != null &&
      mapEquals(_saved!.fields, values) &&
      jsonEncode(_saved!.style.toJson()) == jsonEncode(_style.toJson());

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _save(String data, Map<String, String> values) async {
    final now = DateTime.now();
    final code = CreatedCode(
      id: _saved?.id,
      type: _type,
      fields: values,
      style: _style,
      data: data,
      createdAt: _saved?.createdAt ?? now,
      updatedAt: now,
    );
    await _run(() async {
      final saved = await context.read<QrMakerProvider>().save(code);
      if (mounted) setState(() => _saved = saved);
    }, success: 'Saved to My codes');
  }

  Future<void> _saveToGallery() => _run(() async {
    FocusScope.of(context).unfocus();
    final png = await QrExport.capture(_previewKey);
    await QrExport.saveToGallery(png);
  }, success: 'Saved to your gallery');

  Future<void> _share() => _run(() async {
    FocusScope.of(context).unfocus();
    final png = await QrExport.capture(_previewKey);
    await QrExport.share(png);
  });

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      HapticFeedback.lightImpact();
      if (mounted && success != null) _snack(success);
    } on QrExportException catch (e) {
      if (mounted) _snack(e.message, error: true);
    } catch (e) {
      if (mounted) _snack('Something went wrong: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                error ? Icons.error : Icons.check_circle,
                color: error ? colorScheme.onError : colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: error ? colorScheme.error : colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: error ? 3 : 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final values = _values;
    final isEmpty = QrEncoder.isEmpty(_type, values);
    final error = isEmpty ? null : QrEncoder.validate(_type, values);
    final data = (!isEmpty && error == null)
        ? QrEncoder.encode(_type, values)
        : null;
    final warning = data != null ? _style.scanWarning : null;
    final unchanged = _isUnchanged(values);

    final actions = _ActionDock(
      enabled: data != null,
      busy: _busy,
      unchanged: unchanged,
      onSave: data == null ? null : () => _save(data, values),
      onDownload: _saveToGallery,
      onShare: _share,
    );

    return Scaffold(
      // The floating dock overlays the end of the scrolling form.
      extendBody: true,
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? 'New ${_type.label} QR'
              : 'Edit ${_type.label} QR',
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;

          Widget preview(double maxWidth, {double maxQr = 200}) => _PreviewCard(
            // StyledQr is 1.2x its code size (quiet zone on both sides).
            qrSize: ((maxWidth - 32) / 1.2).clamp(120.0, maxQr),
            previewKey: _previewKey,
            data: data,
            style: _style,
            message: isEmpty
                ? 'Fill in the details below to see your QR code'
                : error,
            isError: !isEmpty,
            warning: warning,
          );

          final form = <Widget>[
            _SectionCard(
              title: 'Content',
              children: [for (final f in _type.fields) _buildField(f, values)],
            ),
            const SizedBox(height: 16),
            _SectionCard(title: 'Style', children: _styleControls()),
          ];

          if (wide) {
            // Tablet / landscape: preview + actions stay in view on the left.
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 380,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Fit preview + actions in the pane's height so the
                      // buttons stay visible on landscape phones.
                      preview(
                        332,
                        maxQr:
                            ((constraints.maxHeight -
                                        48 - // list padding
                                        16 - // gap above actions
                                        _ActionDock.height - // the dock
                                        32 - // card padding
                                        (_style.caption.trim().isEmpty
                                            ? 0
                                            : 40) -
                                        (warning == null ? 0 : 72)) /
                                    1.2)
                                .clamp(120.0, 240.0),
                      ),
                      const SizedBox(height: 16),
                      actions,
                    ],
                  ),
                ),
                VerticalDivider(width: 1, color: colorScheme.outlineVariant),
                Expanded(
                  child: ListView(
                    padding: _centered(constraints.maxWidth - 381, 560, 24),
                    children: form,
                  ),
                ),
              ],
            );
          }

          final pad = _centered(constraints.maxWidth, 600, 16);
          return ListView(
            // Leave room for the floating dock (extendBody adds its height
            // to the bottom view padding).
            padding: pad.copyWith(
              bottom: pad.bottom + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              preview((constraints.maxWidth - 32).clamp(0.0, 600.0)),
              const SizedBox(height: 16),
              ...form,
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 720
          ? null // wide layouts show the dock under the preview
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: actions,
                  ),
                ),
              ),
            ),
    );
  }

  /// Horizontal padding that centers a [maxContent]-wide column.
  static EdgeInsets _centered(double width, double maxContent, double min) {
    final side = ((width - maxContent) / 2).clamp(min, double.infinity);
    return EdgeInsets.fromLTRB(side, min, side, min + 8);
  }

  List<Widget> _styleControls() => [
    _ColorPicker(
      label: 'Code color',
      presets: QrStyle.foregroundPresets,
      selected: _style.foreground,
      onPick: (c) => setState(() => _style = _style.copyWith(foreground: c)),
    ),
    const SizedBox(height: 16),
    _ColorPicker(
      label: 'Background',
      presets: QrStyle.backgroundPresets,
      selected: _style.background,
      onPick: (c) => setState(() => _style = _style.copyWith(background: c)),
    ),
    const SizedBox(height: 20),
    _ShapePicker(
      label: 'Dots',
      rounded: _style.roundDots,
      onChanged: (v) => setState(() => _style = _style.copyWith(roundDots: v)),
    ),
    const SizedBox(height: 12),
    _ShapePicker(
      label: 'Corners',
      rounded: _style.roundEyes,
      onChanged: (v) => setState(() => _style = _style.copyWith(roundEyes: v)),
    ),
    const SizedBox(height: 20),
    TextField(
      controller: _captionController,
      maxLength: 40,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Caption (optional)',
        hintText: 'e.g. Scan to join our Wi-Fi',
      ),
    ),
  ];

  Widget _buildField(QrField f, Map<String, String> values) {
    if (f.isHidden(values)) return const SizedBox.shrink();
    final label = f.required ? '${f.label} *' : f.label;

    switch (f.kind) {
      case QrFieldKind.choice:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _optionValues[f.key],
            // Fill the field width and ellipsize, instead of sizing to the
            // widest item (which overflows on small phones).
            isExpanded: true,
            decoration: InputDecoration(labelText: f.label),
            items: [
              for (final c in f.choices.entries)
                DropdownMenuItem(
                  value: c.key,
                  child: Text(c.value, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _optionValues[f.key] = v ?? ''),
          ),
        );
      case QrFieldKind.toggle:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label),
          value: _optionValues[f.key] == 'true',
          onChanged: (v) => setState(() => _optionValues[f.key] = v.toString()),
        );
      default:
        final isPassword = f.kind == QrFieldKind.password;
        final isMultiline = f.kind == QrFieldKind.multiline;
        final plain = f.kind == QrFieldKind.text || isMultiline;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _controllers[f.key],
            keyboardType: switch (f.kind) {
              QrFieldKind.url => TextInputType.url,
              QrFieldKind.phone => TextInputType.phone,
              QrFieldKind.email => TextInputType.emailAddress,
              QrFieldKind.multiline => TextInputType.multiline,
              _ => TextInputType.text,
            },
            textInputAction: isMultiline
                ? TextInputAction.newline
                : TextInputAction.next,
            minLines: isMultiline ? 2 : 1,
            maxLines: isMultiline ? 5 : 1,
            obscureText: isPassword && !_revealed.contains(f.key),
            autocorrect: plain,
            enableSuggestions: plain,
            textCapitalization: plain
                ? TextCapitalization.sentences
                : TextCapitalization.none,
            decoration: InputDecoration(
              labelText: label,
              hintText: f.hint,
              suffixIcon: isPassword
                  ? IconButton(
                      tooltip: _revealed.contains(f.key)
                          ? 'Hide password'
                          : 'Show password',
                      icon: Icon(
                        _revealed.contains(f.key)
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() {
                        if (!_revealed.remove(f.key)) _revealed.add(f.key);
                      }),
                    )
                  : null,
            ),
          ),
        );
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      // Transparent Material so ListTiles inside show their ink.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// The live QR (or a hint/error placeholder of the same size) on a card.
class _PreviewCard extends StatelessWidget {
  final double qrSize;
  final GlobalKey previewKey;
  final String? data;
  final QrStyle style;
  final String? message;
  final bool isError;
  final String? warning;

  const _PreviewCard({
    required this.qrSize,
    required this.previewKey,
    required this.data,
    required this.style,
    required this.message,
    required this.isError,
    required this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final box = qrSize * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: data != null
                  ? RepaintBoundary(
                      key: previewKey,
                      child: StyledQr(data: data!, style: style, size: qrSize),
                    )
                  : _Placeholder(
                      size: box,
                      message: message ?? '',
                      isError: isError,
                    ),
            ),
          ),
          if (warning != null) ...[
            const SizedBox(height: 12),
            _WarningBanner(message: warning!),
          ],
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double size;
  final String message;
  final bool isError;
  const _Placeholder({
    required this.size,
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Same footprint as the StyledQr it stands in for, so nothing jumps.
    return Container(
      width: size,
      height: size,
      color: colorScheme.surfaceContainer,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.qr_code_2,
            size: size * 0.2,
            color: isError
                ? colorScheme.error
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isError
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The action dock: Save and Download as compact tiles, Share as the
/// prominent gradient call to action. Floats above the form on phones.
class _ActionDock extends StatelessWidget {
  static const double height = 76; // 10 + 56 + 10

  final bool enabled;
  final bool busy;
  final bool unchanged;
  final VoidCallback? onSave;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  const _ActionDock({
    required this.enabled,
    required this.busy,
    required this.unchanged,
    required this.onSave,
    required this.onDownload,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canAct = enabled && !busy;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _DockTile(
            icon: unchanged
                ? Icons.bookmark_added
                : Icons.bookmark_add_outlined,
            label: unchanged ? 'Saved' : 'Save',
            tooltip: unchanged ? 'Saved to My codes' : 'Save to My codes',
            done: unchanged,
            onTap: canAct && !unchanged ? onSave : null,
          ),
          const SizedBox(width: 8),
          _DockTile(
            icon: Icons.download_rounded,
            label: 'Download',
            tooltip: 'Save image to your gallery',
            onTap: canAct ? onDownload : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ShareButton(busy: busy, onTap: canAct ? onShare : null),
          ),
        ],
      ),
    );
  }
}

/// Square tile: icon over a short label, tinted with the brand color.
class _DockTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool done;
  final VoidCallback? onTap;

  const _DockTile({
    required this.icon,
    required this.label,
    required this.tooltip,
    this.done = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final fg = done || enabled
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.35);
    final bg = done
        ? colorScheme.primary.withValues(alpha: 0.16)
        : enabled
        ? colorScheme.primary.withValues(alpha: 0.10)
        : colorScheme.onSurface.withValues(alpha: 0.05);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        excludeSemantics: true,
        child: SizedBox(
          width: 68,
          height: 56,
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        icon,
                        key: ValueKey(icon),
                        color: fg,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient pill with a soft glow; shows a spinner while working.
class _ShareButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onTap;

  const _ShareButton({required this.busy, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final primary = colorScheme.primary;
    final deep = Color.lerp(primary, Colors.black, 0.18)!;
    final fg = enabled || busy
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withValues(alpha: 0.38);

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Share QR code',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: enabled || busy
              ? LinearGradient(
                  colors: [primary, deep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled || busy
              ? null
              : colorScheme.onSurface.withValues(alpha: 0.07),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: busy
                            ? SizedBox.square(
                                key: const ValueKey('busy'),
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: fg,
                                ),
                              )
                            : Icon(
                                Icons.ios_share_rounded,
                                key: const ValueKey('icon'),
                                color: fg,
                                size: 22,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Share QR',
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final String label;
  final List<int> presets;
  final int selected;
  final ValueChanged<int> onPick;

  const _ColorPicker({
    required this.label,
    required this.presets,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        // Dots shrink (down to 32) so a whole palette fits on one row;
        // below that they wrap.
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final fit =
                (constraints.maxWidth - gap * (presets.length - 1)) /
                presets.length;
            final dot = fit.clamp(32.0, 40.0);
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final c in presets)
                  Semantics(
                    button: true,
                    selected: c == selected,
                    label:
                        '$label #${(c & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onPick(c),
                      child: Container(
                        width: dot,
                        height: dot,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c == selected
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.5),
                            width: c == selected ? 3 : 1,
                          ),
                        ),
                        child: c == selected
                            ? Icon(
                                Icons.check,
                                size: dot / 2,
                                color: Color(c).computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ShapePicker extends StatelessWidget {
  final String label;
  final bool rounded;
  final ValueChanged<bool> onChanged;

  const _ShapePicker({
    required this.label,
    required this.rounded,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow cards (small phones, large text): label above, no icons.
        final stacked =
            constraints.maxWidth < MediaQuery.textScalerOf(context).scale(300);

        final picker = SegmentedButton<bool>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: colorScheme.primary.withValues(
              alpha: 0.12,
            ),
            selectedForegroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          segments: [
            ButtonSegment(
              value: false,
              label: const Text('Square', maxLines: 1, softWrap: false),
              icon: stacked ? null : const Icon(Icons.crop_square),
            ),
            ButtonSegment(
              value: true,
              label: const Text('Round', maxLines: 1, softWrap: false),
              icon: stacked ? null : const Icon(Icons.circle_outlined),
            ),
          ],
          selected: {rounded},
          onSelectionChanged: (s) => onChanged(s.first),
        );

        final text = Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [text, const SizedBox(height: 8), picker],
          );
        }
        return Row(
          children: [
            SizedBox(width: 72, child: text),
            Expanded(child: picker),
          ],
        );
      },
    );
  }
}
