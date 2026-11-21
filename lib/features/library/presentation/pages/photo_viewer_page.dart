import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/image_export.dart';
import '../../../post_maker/presentation/pages/post_editor_page.dart';
import '../providers/library_provider.dart';
import '../widgets/library_ui.dart';

/// Full-screen swipeable viewer with pinch-zoom and photo actions.
class PhotoViewerPage extends StatefulWidget {
  /// The folder being browsed (null = all photos).
  final int? folderId;
  final int initialPhotoId;

  const PhotoViewerPage({
    super.key,
    required this.folderId,
    required this.initialPhotoId,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final photos = context.read<LibraryProvider>().photosIn(widget.folderId);
    _index = photos
        .indexWhere((p) => p.id == widget.initialPhotoId)
        .clamp(0, photos.isEmpty ? 0 : photos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final photos = provider.photosIn(widget.folderId);
    if (photos.isEmpty) {
      // Last photo was deleted or moved away.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold(backgroundColor: Colors.black);
    }
    final index = _index.clamp(0, photos.length - 1);
    if (index != _index) {
      // The list shrank under us (delete/move): keep the pager in range.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _index = index);
        if (_controller.hasClients) _controller.jumpToPage(index);
      });
    }
    final photo = photos[index];
    final folderName = provider.folderById(photo.folderId)?.name;

    Future<void> move() async {
      final choice = await pickFolder(
        context,
        title: 'Move photo to…',
        current: photo.folderId,
      );
      if (choice == null) return;
      await provider.movePhotos([photo.id], choice.folderId);
      if (context.mounted) {
        final name = provider.folderById(choice.folderId)?.name ?? 'No folder';
        showLibrarySnack(context, 'Moved to $name');
      }
    }

    Future<void> delete() async {
      final ok = await confirmDelete(
        context,
        title: 'Delete this photo?',
        message: 'It will be removed from Locus.',
      );
      if (ok) await provider.deletePhotos([photo.id]);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text('${index + 1} of ${photos.length}'),
            if (folderName != null)
              Text(
                folderName,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: Image.file(
              File(photos[i].path),
              fit: BoxFit.contain,
              errorBuilder: (context, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 48,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                _ViewerAction(
                  icon: Icons.format_quote_rounded,
                  label: 'Add text',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostEditorPage(
                        imagePath: photo.path,
                        folderId: photo.folderId,
                      ),
                    ),
                  ),
                ),
                _ViewerAction(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () => ImageExport.shareFiles([photo.path]),
                ),
                _ViewerAction(
                  icon: Icons.drive_file_move_outlined,
                  label: 'Move',
                  onTap: move,
                ),
                _ViewerAction(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onTap: delete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ViewerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.3),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
