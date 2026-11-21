import 'dart:convert';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/image_export.dart';
import '../../../../core/widgets/color_dots_picker.dart';
import '../../../../core/widgets/export_actions.dart';
import '../../../../core/widgets/section_card.dart';
import '../../domain/entities/created_code.dart';
import '../../domain/entities/qr_style.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/qr_encoder.dart';
import '../providers/qr_maker_provider.dart';
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
    final png = await ImageExport.capture(_previewKey);
    await ImageExport.saveToGallery(png, prefix: 'locus_qr');
  }, success: 'Saved to your gallery');

  Future<void> _share() => _run(() async {
    FocusScope.of(context).unfocus();
    final png = await ImageExport.capture(_previewKey);
    await ImageExport.share(png, prefix: 'locus_qr');
  });

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      HapticFeedback.lightImpact();
      if (mounted && success != null) _snack(success);
    } on ImageExportException catch (e) {
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
                color: error ? colorScheme.onError : colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: error ? colorScheme.error : null,
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

    final actions = ExportActions(
      canAct: data != null && !_busy,
      unchanged: unchanged,
      onSave: data == null ? null : () => _save(data, values),
      onGallery: _saveToGallery,
      onShare: _share,
    );

    return Scaffold(
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
            SectionCard(
              title: 'Content',
              children: [for (final f in _type.fields) _buildField(f, values)],
            ),
            const SizedBox(height: 16),
            SectionCard(title: 'Style', children: _styleControls()),
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
                                        ExportActions.height - // actions row
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

          return ListView(
            padding: _centered(constraints.maxWidth, 600, 16),
            children: [
              preview((constraints.maxWidth - 32).clamp(0.0, 600.0)),
              const SizedBox(height: 16),
              ...form,
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 720
          ? null // wide layouts show the actions under the preview
          : ExportActionBar(child: actions),
    );
  }

  /// Horizontal padding that centers a [maxContent]-wide column.
  static EdgeInsets _centered(double width, double maxContent, double min) {
    final side = ((width - maxContent) / 2).clamp(min, double.infinity);
    return EdgeInsets.fromLTRB(side, min, side, min + 8);
  }

  List<Widget> _styleControls() => [
    ColorDotsPicker(
      label: 'Code color',
      presets: QrStyle.foregroundPresets,
      selected: _style.foreground,
      onPick: (c) => setState(() => _style = _style.copyWith(foreground: c)),
    ),
    const SizedBox(height: 16),
    ColorDotsPicker(
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
