import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../post_maker/presentation/pages/post_editor_page.dart';
import '../../domain/entities/library_entities.dart';
import '../providers/library_provider.dart';
import '../widgets/library_ui.dart';
import 'folder_page.dart';

/// The Photos tab: add photos, browse "All photos" and folders.
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  Future<void> _addPhotos(BuildContext context, PhotoSource source) async {
    final provider = context.read<LibraryProvider>();
    final paths = await PhotoPicker.pick(source);
    if (paths.isEmpty || !context.mounted) return;

    int? folderId;
    if (provider.folders.isNotEmpty) {
      final choice = await pickFolder(
        context,
        title: paths.length == 1
            ? 'Add the photo to…'
            : 'Add ${paths.length} photos to…',
      );
      if (choice == null) return; // dismissed: nothing added
      folderId = choice.folderId;
    }
    final n = await provider.importFiles(paths, folderId);
    if (context.mounted) {
      final where = provider.folderById(folderId)?.name;
      showLibrarySnack(
        context,
        'Added ${photoCount(n)}${where == null ? '' : ' to $where'}',
      );
    }
  }

  Future<void> _newFolder(BuildContext context) async {
    final provider = context.read<LibraryProvider>();
    final result = await showFolderDialog(context);
    if (result != null) await provider.createFolder(result.$1, result.$2);
  }

  void _openFolder(BuildContext context, int? folderId) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => FolderPage(folderId: folderId)));

  Future<void> _folderOptions(BuildContext context, PhotoFolder folder) async {
    final provider = context.read<LibraryProvider>();
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename or recolor'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                'Delete folder',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      final result = await showFolderDialog(context, initial: folder);
      if (result != null) {
        await provider.updateFolder(
          PhotoFolder(
            id: folder.id,
            name: result.$1,
            color: result.$2,
            createdAt: folder.createdAt,
          ),
        );
      }
    } else if (action == 'delete') {
      final n = provider.countIn(folder.id);
      final ok = await confirmDelete(
        context,
        title: 'Delete "${folder.name}"?',
        message: n == 0
            ? 'The folder is empty.'
            : 'Its ${photoCount(n)} stay in All photos.',
      );
      if (ok) await provider.deleteFolder(folder.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (provider.isLoading && provider.photos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickTile(
                icon: Icons.photo_camera_outlined,
                title: 'Take photo',
                onTap: () => _addPhotos(context, PhotoSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickTile(
                icon: Icons.add_photo_alternate_outlined,
                title: 'Import',
                onTap: () => _addPhotos(context, PhotoSource.gallery),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickTile(
                icon: Icons.format_quote_rounded,
                title: 'Text post',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PostEditorPage()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Wrap, not Row: with large text on small phones the button moves
        // under the title instead of squeezing it.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Folders',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            TextButton.icon(
              onPressed: () => _newFolder(context),
              icon: const Icon(Icons.create_new_folder_outlined, size: 20),
              label: const Text('New folder'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (provider.error != null)
          Text(provider.error!, style: TextStyle(color: colorScheme.error)),
        LayoutBuilder(
          builder: (context, constraints) {
            // Square covers with the name and count underneath (Google
            // Photos style). The row height follows the real tile width.
            const gap = 14.0;
            final cols = ((constraints.maxWidth + gap) / (200 + gap)).ceil();
            final tileWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
            final textHeight = MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.3).scale(44);
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 16,
                crossAxisSpacing: gap,
                mainAxisExtent: tileWidth + 8 + textHeight + 4,
              ),
              children: [
                _FolderTile(
                  name: 'All photos',
                  color: colorScheme.primary,
                  icon: Icons.photo_library_outlined,
                  count: provider.countIn(null),
                  cover: provider.coverOf(null)?.path,
                  onTap: () => _openFolder(context, null),
                ),
                for (final f in provider.folders)
                  _FolderTile(
                    name: f.name,
                    color: Color(f.color),
                    icon: Icons.folder_outlined,
                    count: provider.countIn(f.id),
                    cover: provider.coverOf(f.id)?.path,
                    onTap: () => _openFolder(context, f.id),
                    onMore: () => _folderOptions(context, f),
                  ),
              ],
            );
          },
        ),
        if (provider.folders.isEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Tip: create folders like "Family" or "Receipts" to keep photos '
            'organized. Long-press a folder to rename or delete it.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.3),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final String name;
  final Color color;
  final IconData icon;
  final int count;
  final String? cover;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  const _FolderTile({
    required this.name,
    required this.color,
    required this.icon,
    required this.count,
    required this.cover,
    required this.onTap,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      onLongPress: onMore,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: cover != null
                  ? PhotoThumb(path: cover!)
                  : ColoredBox(
                      color: color.withValues(alpha: 0.14),
                      child: Icon(icon, color: color, size: 44),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: scaler,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      photoCount(count),
                      maxLines: 1,
                      textScaler: scaler,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onMore != null)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    tooltip: 'Folder options',
                    onPressed: onMore,
                    icon: const Icon(Icons.more_vert),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
