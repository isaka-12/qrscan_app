import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/color_dots_picker.dart';
import '../../domain/entities/library_entities.dart';
import '../providers/library_provider.dart';

// ── Picking photos ─────────────────────────────────────────────────────────

enum PhotoSource { camera, gallery }

class PhotoPicker {
  PhotoPicker._();
  static final _picker = ImagePicker();

  /// Paths of the picked images (empty when cancelled). Large images are
  /// scaled down to keep the library small.
  static Future<List<String>> pick(PhotoSource source) async {
    if (source == PhotoSource.camera) {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2560,
        maxHeight: 2560,
        imageQuality: 90,
      );
      return x == null ? const [] : [x.path];
    }
    final xs = await _picker.pickMultiImage(
      maxWidth: 2560,
      maxHeight: 2560,
      imageQuality: 90,
    );
    return [for (final x in xs) x.path];
  }

  static Future<PhotoSource?> chooseSource(BuildContext context) =>
      showModalBottomSheet<PhotoSource>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, PhotoSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, PhotoSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
}

// ── Folders ───────────────────────────────────────────────────────────────

/// Result of [pickFolder]: [folderId] null means "no folder".
class FolderChoice {
  final int? folderId;
  const FolderChoice(this.folderId);
}

/// Name + color dialog for creating or editing a folder.
Future<(String, int)?> showFolderDialog(
  BuildContext context, {
  PhotoFolder? initial,
}) => showDialog<(String, int)>(
  context: context,
  builder: (_) => _FolderDialog(initial: initial),
);

/// Owns its text controller, so the controller lives exactly as long as the
/// dialog (including its closing animation). Disposing it when the dialog's
/// future completed crashed the app: the field was still being drawn.
class _FolderDialog extends StatefulWidget {
  final PhotoFolder? initial;
  const _FolderDialog({this.initial});

  @override
  State<_FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<_FolderDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late int _color = widget.initial?.color ?? PhotoFolder.colorPresets.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, (name, _color));
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initial == null;
    final canSubmit = _name.text.trim().isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isNew ? 'New folder' : 'Edit folder'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Folder name',
                  hintText: 'e.g. Family, Receipts, Trips',
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              ColorDotsPicker(
                label: 'Color',
                presets: PhotoFolder.colorPresets,
                selected: _color,
                onPick: (c) => setState(() => _color = c),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSubmit ? _submit : null,
          child: Text(isNew ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}

/// Bottom sheet to choose a destination folder (or create one).
/// Returns null when dismissed.
Future<FolderChoice?> pickFolder(
  BuildContext context, {
  required String title,
  int? current,
}) async {
  final provider = context.read<LibraryProvider>();
  final picked = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final folders = provider.folders;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text('New folder…'),
                onTap: () => Navigator.pop(ctx, 'new'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: const Text('No folder'),
                trailing: current == null ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, const FolderChoice(null)),
              ),
              for (final f in folders)
                ListTile(
                  leading: Icon(Icons.folder, color: Color(f.color)),
                  title: Text(f.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_count(provider.countIn(f.id))),
                  trailing: current == f.id ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(ctx, FolderChoice(f.id)),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );

  if (picked == 'new' && context.mounted) {
    final result = await showFolderDialog(context);
    if (result == null) return null;
    final folder = await provider.createFolder(result.$1, result.$2);
    return FolderChoice(folder.id);
  }
  return picked is FolderChoice ? picked : null;
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  String action = 'Delete',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok == true;
}

String _count(int n) => n == 1 ? '1 photo' : '$n photos';
String photoCount(int n) => _count(n);

void showLibrarySnack(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
}

// ── Thumbnails ────────────────────────────────────────────────────────────

/// A photo decoded at the size it's shown (not full resolution), so long
/// grids stay light on memory.
class PhotoThumb extends StatelessWidget {
  final String path;
  final BoxFit fit;

  const PhotoThumb({super.key, required this.path, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
        return Image.file(
          File(path),
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: (w * dpr).round().clamp(64, 1024),
          gaplessPlayback: true,
          errorBuilder: (context, _, _) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
