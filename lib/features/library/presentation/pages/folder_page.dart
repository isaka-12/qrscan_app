import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/image_export.dart';
import '../providers/library_provider.dart';
import '../widgets/library_ui.dart';
import 'photo_viewer_page.dart';

/// Photos in one folder ([folderId] set) or all photos ([folderId] null).
/// Long-press starts selecting; then move, share or delete in bulk.
class FolderPage extends StatefulWidget {
  final int? folderId;
  const FolderPage({super.key, required this.folderId});

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  final Set<int> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  void _toggle(int id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  Future<void> _add(PhotoSource source) async {
    final provider = context.read<LibraryProvider>();
    final paths = await PhotoPicker.pick(source);
    if (paths.isEmpty) return;
    final n = await provider.importFiles(paths, widget.folderId);
    if (mounted) showLibrarySnack(context, 'Added ${photoCount(n)}');
  }

  Future<void> _moveSelected() async {
    final provider = context.read<LibraryProvider>();
    final ids = _selected.toList();
    final choice = await pickFolder(
      context,
      title: 'Move ${photoCount(ids.length)} to…',
      current: widget.folderId,
    );
    if (choice == null) return;
    await provider.movePhotos(ids, choice.folderId);
    if (!mounted) return;
    setState(_selected.clear);
    final name = provider.folderById(choice.folderId)?.name ?? 'No folder';
    showLibrarySnack(context, 'Moved ${photoCount(ids.length)} to $name');
  }

  Future<void> _shareSelected() async {
    final provider = context.read<LibraryProvider>();
    final paths = [
      for (final p in provider.photos)
        if (_selected.contains(p.id)) p.path,
    ];
    try {
      await ImageExport.shareFiles(paths);
    } catch (e) {
      if (mounted) {
        showLibrarySnack(context, 'Could not share: $e', error: true);
      }
    }
  }

  Future<void> _deleteSelected() async {
    final provider = context.read<LibraryProvider>();
    final n = _selected.length;
    final ok = await confirmDelete(
      context,
      title: 'Delete ${photoCount(n)}?',
      message:
          'They will be removed from Locus. Copies in your phone\'s gallery '
          'are not affected.',
    );
    if (!ok) return;
    await provider.deletePhotos(_selected.toList());
    if (mounted) setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final folder = provider.folderById(widget.folderId);
    final photos = provider.photosIn(widget.folderId);
    final colorScheme = Theme.of(context).colorScheme;
    // Drop selections of photos that were moved out or deleted.
    _selected.removeWhere((id) => !photos.any((p) => p.id == id));

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        appBar: _selecting
            ? AppBar(
                leading: IconButton(
                  tooltip: 'Clear selection',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_selected.clear),
                ),
                title: Text('${_selected.length} selected'),
                actions: [
                  IconButton(
                    tooltip: 'Select all',
                    icon: const Icon(Icons.select_all),
                    onPressed: () => setState(
                      () => _selected.addAll(photos.map((p) => p.id)),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Share',
                    icon: const Icon(Icons.share_outlined),
                    onPressed: _shareSelected,
                  ),
                  IconButton(
                    tooltip: 'Move to folder',
                    icon: const Icon(Icons.drive_file_move_outlined),
                    onPressed: _moveSelected,
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _deleteSelected,
                  ),
                ],
              )
            : AppBar(
                title: Text(folder?.name ?? 'All photos'),
                actions: [
                  IconButton(
                    tooltip: 'Take a photo',
                    icon: const Icon(Icons.photo_camera_outlined),
                    onPressed: () => _add(PhotoSource.camera),
                  ),
                  IconButton(
                    tooltip: 'Import from gallery',
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    onPressed: () => _add(PhotoSource.gallery),
                  ),
                ],
              ),
        body: photos.isEmpty
            ? _EmptyFolder(
                onCamera: () => _add(PhotoSource.camera),
                onImport: () => _add(PhotoSource.gallery),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(4),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: photos.length,
                itemBuilder: (context, i) {
                  final photo = photos[i];
                  final selected = _selected.contains(photo.id);
                  return Semantics(
                    selected: selected,
                    label: 'Photo ${i + 1} of ${photos.length}',
                    button: true,
                    child: GestureDetector(
                      onTap: () => _selecting
                          ? _toggle(photo.id)
                          : Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PhotoViewerPage(
                                  folderId: widget.folderId,
                                  initialPhotoId: photo.id,
                                ),
                              ),
                            ),
                      onLongPress: () => _toggle(photo.id),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedPadding(
                            duration: const Duration(milliseconds: 150),
                            padding: EdgeInsets.all(selected ? 8 : 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                selected ? 10 : 4,
                              ),
                              child: PhotoThumb(path: photo.path),
                            ),
                          ),
                          if (_selecting)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: selected
                                    ? colorScheme.primary
                                    : Colors.white,
                                shadows: const [
                                  Shadow(blurRadius: 4, color: Colors.black45),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyFolder extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onImport;

  const _EmptyFolder({required this.onCamera, required this.onImport});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 56,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No photos here yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Take photo'),
                ),
                FilledButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
