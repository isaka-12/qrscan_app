import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/image_export.dart';
import '../../../../core/widgets/color_dots_picker.dart';
import '../../../../core/widgets/export_actions.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../../../library/presentation/widgets/library_ui.dart';
import '../../domain/post_style.dart';
import '../../domain/quotes.dart';
import '../widgets/post_canvas.dart';

/// Put text or a quote on a photo, then save it to Photos, the gallery,
/// or share it. Opens on a photo picker when no [imagePath] is given.
class PostEditorPage extends StatefulWidget {
  final String? imagePath;

  /// Library folder the finished post is saved into (null = no folder).
  final int? folderId;

  const PostEditorPage({super.key, this.imagePath, this.folderId});

  @override
  State<PostEditorPage> createState() => _PostEditorPageState();
}

class _PostEditorPageState extends State<PostEditorPage> {
  final _canvasKey = GlobalKey();
  late final TextEditingController _text;
  late final TextEditingController _author;
  String? _imagePath;
  double? _imageRatio;
  PostStyle _style = const PostStyle();
  bool _busy = false;
  String? _savedSignature;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController()
      ..addListener(
        () => setState(() => _style = _style.copyWith(text: _text.text)),
      );
    _author = TextEditingController()
      ..addListener(
        () => setState(() => _style = _style.copyWith(author: _author.text)),
      );
    _setImage(widget.imagePath);
  }

  @override
  void dispose() {
    _text.dispose();
    _author.dispose();
    super.dispose();
  }

  // ── Photo ─────────────────────────────────────────────────────────────────

  void _setImage(String? path) {
    _imagePath = path;
    _imageRatio = null;
    if (path == null) return;
    // Read the photo's own width/height for the "Original" format.
    final stream = FileImage(File(path)).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      final ratio = info.image.width / info.image.height;
      info.dispose();
      stream.removeListener(listener);
      if (mounted && _imagePath == path) {
        setState(() => _imageRatio = ratio);
      }
    }, onError: (_, _) => stream.removeListener(listener));
    stream.addListener(listener);
  }

  double get _ratio => _style.aspect == PostAspect.original
      ? (_imageRatio ?? 1)
      : _style.aspect.ratio;

  String get _signature => '$_imagePath|${_style.signature}';

  Future<void> _choosePhoto() async {
    final library = context.read<LibraryProvider>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('From Locus Photos'),
              subtitle: Text(photoCount(library.photos.length)),
              enabled: library.photos.isNotEmpty,
              onTap: () => Navigator.pop(ctx, 'library'),
            ),
            ListTile(
              leading: const Icon(Icons.add_photo_alternate_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    await _pickFrom(choice);
  }

  Future<void> _pickFrom(String source) async {
    String? path;
    if (source == 'library') {
      path = await _pickFromLibrary();
    } else {
      final paths = await PhotoPicker.pick(
        source == 'camera' ? PhotoSource.camera : PhotoSource.gallery,
      );
      path = paths.isEmpty ? null : paths.first;
    }
    if (path != null && mounted) setState(() => _setImage(path));
  }

  Future<String?> _pickFromLibrary() {
    final photos = context.read<LibraryProvider>().photos;
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.7,
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 130,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: photos.length,
            itemBuilder: (_, i) => InkWell(
              onTap: () => Navigator.pop(ctx, photos[i].path),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: PhotoThumb(path: photos[i].path),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickQuote() async {
    final quote = await showModalBottomSheet<Quote>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => const _QuoteSheet(),
    );
    if (quote == null) return;
    _text.text = quote.text;
    _author.text = quote.author;
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      HapticFeedback.lightImpact();
      if (mounted && success != null) showLibrarySnack(context, success);
    } on ImageExportException catch (e) {
      if (mounted) showLibrarySnack(context, e.message, error: true);
    } catch (e) {
      if (mounted) {
        showLibrarySnack(context, 'Something went wrong: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _run(() async {
    FocusScope.of(context).unfocus();
    final library = context.read<LibraryProvider>();
    final signature = _signature;
    final png = await ImageExport.capture(_canvasKey);
    await library.addPng(png, widget.folderId);
    if (mounted) setState(() => _savedSignature = signature);
  }, success: 'Saved to Photos');

  Future<void> _download() => _run(() async {
    FocusScope.of(context).unfocus();
    final png = await ImageExport.capture(_canvasKey);
    await ImageExport.saveToGallery(png, prefix: 'locus_post');
  }, success: 'Saved to your gallery');

  Future<void> _share() => _run(() async {
    FocusScope.of(context).unfocus();
    final png = await ImageExport.capture(_canvasKey);
    await ImageExport.share(png, prefix: 'locus_post');
  });

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_imagePath == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Text on photo')),
        body: _SourceChooser(
          libraryCount: context.watch<LibraryProvider>().photos.length,
          onPick: _pickFrom,
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final actions = ExportActions(
      canAct: !_busy,
      unchanged: _savedSignature == _signature,
      onSave: _save,
      onGallery: _download,
      onShare: _share,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Text on photo'),
        actions: [
          IconButton(
            tooltip: 'Change photo',
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: _choosePhoto,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final form = <Widget>[
            SectionCard(title: 'Text', children: _textControls()),
            const SizedBox(height: 16),
            SectionCard(title: 'Style', children: _styleControls()),
            const SizedBox(height: 16),
            SectionCard(title: 'Format', children: _formatControls()),
          ];

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 440,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _preview(
                        maxWidth: 392,
                        maxHeight:
                            constraints.maxHeight -
                            48 - // list padding
                            24 - // card padding
                            28 - // hint
                            16 - // gap
                            ExportActions.height,
                      ),
                      const SizedBox(height: 16),
                      actions,
                    ],
                  ),
                ),
                VerticalDivider(width: 1, color: colorScheme.outlineVariant),
                Expanded(
                  child: ListView(
                    padding: _centered(constraints.maxWidth - 441, 560, 24),
                    children: form,
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: _centered(constraints.maxWidth, 600, 16),
            children: [
              _preview(
                maxWidth: math.min(constraints.maxWidth, 600) - 32 - 24,
                // Keep tall formats (stories) from filling the screen.
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              const SizedBox(height: 16),
              ...form,
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 720
          ? null
          : ExportActionBar(child: actions),
    );
  }

  static EdgeInsets _centered(double width, double maxContent, double min) {
    final side = ((width - maxContent) / 2).clamp(min, double.infinity);
    return EdgeInsets.fromLTRB(side, min, side, min + 8);
  }

  Widget _preview({required double maxWidth, required double maxHeight}) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratio = _ratio;
    final width = math.max(120.0, math.min(maxWidth, maxHeight * ratio));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: width,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RepaintBoundary(
                  key: _canvasKey,
                  child: PostCanvas(
                    image: FileImage(File(_imagePath!)),
                    aspectRatio: ratio,
                    style: _style,
                    onMoveText: (dx, dy) =>
                        setState(() => _style = _style.moved(dx, dy)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.open_with_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Drag the text to move it',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  List<Widget> _textControls() => [
    TextField(
      controller: _text,
      minLines: 2,
      maxLines: 5,
      maxLength: 240,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Text',
        hintText: 'Write something, or pick a quote',
        alignLabelWithHint: true,
      ),
    ),
    const SizedBox(height: 4),
    Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _pickQuote,
        icon: const Icon(Icons.format_quote_rounded),
        label: const Text('Pick a quote'),
      ),
    ),
    const SizedBox(height: 16),
    TextField(
      controller: _author,
      maxLength: 60,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Author or signature (optional)',
      ),
    ),
  ];

  List<Widget> _styleControls() {
    final colorScheme = Theme.of(context).colorScheme;
    return [
      _label('Font'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < PostFont.presets.length; i++)
            ChoiceChip(
              label: Text(
                PostFont.presets[i].label,
                style: TextStyle(fontFamily: PostFont.presets[i].family),
              ),
              selected: _style.font == i,
              onSelected: (_) =>
                  setState(() => _style = _style.copyWith(font: i)),
            ),
        ],
      ),
      const SizedBox(height: 16),
      ColorDotsPicker(
        label: 'Text color',
        presets: PostStyle.colorPresets,
        selected: _style.color,
        onPick: (c) => setState(() => _style = _style.copyWith(color: c)),
      ),
      const SizedBox(height: 16),
      _label('Size'),
      Row(
        children: [
          Icon(
            Icons.text_decrease,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          Expanded(
            child: Slider(
              min: PostStyle.minScale,
              max: PostStyle.maxScale,
              value: _style.scale,
              onChanged: (v) =>
                  setState(() => _style = _style.copyWith(scale: v)),
            ),
          ),
          Icon(
            Icons.text_increase,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<PostAlign>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: colorScheme.primary.withValues(
                alpha: 0.12,
              ),
              selectedForegroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            segments: const [
              ButtonSegment(
                value: PostAlign.left,
                icon: Icon(Icons.format_align_left),
                tooltip: 'Align left',
              ),
              ButtonSegment(
                value: PostAlign.center,
                icon: Icon(Icons.format_align_center),
                tooltip: 'Center',
              ),
              ButtonSegment(
                value: PostAlign.right,
                icon: Icon(Icons.format_align_right),
                tooltip: 'Align right',
              ),
            ],
            selected: {_style.align},
            onSelectionChanged: (s) =>
                setState(() => _style = _style.copyWith(align: s.first)),
          ),
          FilterChip(
            avatar: const Icon(Icons.format_bold, size: 18),
            label: const Text('Bold'),
            selected: _style.bold,
            showCheckmark: false,
            onSelected: (v) =>
                setState(() => _style = _style.copyWith(bold: v)),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _label('Background'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final b in PostBackdrop.values)
            ChoiceChip(
              label: Text(b.label),
              selected: _style.backdrop == b,
              onSelected: (_) =>
                  setState(() => _style = _style.copyWith(backdrop: b)),
            ),
        ],
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _formatControls() => [
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in PostAspect.values)
          ChoiceChip(
            label: Text(a.label),
            selected: _style.aspect == a,
            onSelected: a == PostAspect.original && _imageRatio == null
                ? null
                : (_) => setState(() => _style = _style.copyWith(aspect: a)),
          ),
      ],
    ),
    const SizedBox(height: 8),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () =>
            setState(() => _style = _style.copyWith(dx: 0.5, dy: 0.75)),
        icon: const Icon(Icons.center_focus_strong_outlined),
        label: const Text('Reset text position'),
      ),
    ),
  ];
}

/// Shown before a photo is chosen.
class _SourceChooser extends StatelessWidget {
  final int libraryCount;
  final ValueChanged<String> onPick;

  const _SourceChooser({required this.libraryCount, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget option(
      IconData icon,
      String title,
      String subtitle,
      String value, {
      bool enabled = true,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            enabled: enabled,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(
                  alpha: enabled ? 0.1 : 0.04,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: enabled
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onPick(value),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.format_quote_rounded,
              size: 56,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Pick a photo for your post',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Add your words or a quote, style it, and share it to your '
              'socials.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            option(
              Icons.photo_library_outlined,
              'From Locus Photos',
              libraryCount == 0 ? 'No photos yet' : photoCount(libraryCount),
              'library',
              enabled: libraryCount > 0,
            ),
            option(
              Icons.add_photo_alternate_outlined,
              'Choose from gallery',
              'Any photo on your phone',
              'gallery',
            ),
            option(
              Icons.photo_camera_outlined,
              'Take a photo',
              'Use the camera now',
              'camera',
            ),
          ],
        ),
      ),
    );
  }
}

/// Browse the bundled quotes by category.
class _QuoteSheet extends StatefulWidget {
  const _QuoteSheet();

  @override
  State<_QuoteSheet> createState() => _QuoteSheetState();
}

class _QuoteSheetState extends State<_QuoteSheet> {
  String _category = Quote.categories.first;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final quotes = Quote.all.where((q) => q.category == _category).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'Pick a quote',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final c in Quote.categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: quotes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final q = quotes[i];
                  return Material(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, q),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.text,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontFamily: 'serif'),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '— ${q.author}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
