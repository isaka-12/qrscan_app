import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/date_labels.dart';
import '../../../post_maker/presentation/pages/post_editor_page.dart';
import '../../domain/entities/created_code.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/qr_encoder.dart';
import '../providers/qr_maker_provider.dart';
import '../widgets/styled_qr.dart';
import 'qr_editor_page.dart';

/// The Create tab, in the same style as Scans and Settings: section
/// headers over rounded groups. QR code types, photo post, and My codes
/// (swipe to delete with Undo, long-press for actions).
class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<void> _delete(BuildContext context, CreatedCode code) async {
    final provider = context.read<QrMakerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (code.id == null) return;
    await provider.delete(code.id!);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Code deleted'),
          action: SnackBarAction(
            label: 'Undo',
            // Saved again as a new row (same content and dates).
            onPressed: () => provider.save(
              CreatedCode(
                type: code.type,
                fields: code.fields,
                style: code.style,
                data: code.data,
                createdAt: code.createdAt,
                updatedAt: code.updatedAt,
              ),
            ),
          ),
        ),
      );
  }

  Future<void> _actions(BuildContext context, CreatedCode code) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: StyledQr(
                  data: code.data,
                  style: code.style,
                  size: 36,
                  showCaption: false,
                ),
              ),
              title: Text(
                QrEncoder.summary(code.type, code.fields),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(code.type.label),
            ),
            const Divider(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit, save or share'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                'Delete',
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
    if (action == 'edit') _open(context, QrEditorPage.edit(code: code));
    if (action == 'delete') await _delete(context, code);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QrMakerProvider>();
    final codes = provider.codes;
    final colorScheme = Theme.of(context).colorScheme;
    // Type tiles grow with the system font size, up to a point.
    final textScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.3);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        const _SectionHeader(title: 'QR code'),
        _Group(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // ~4 per row on phones, all 7 in one row on tablets.
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 96,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                mainAxisExtent: 72 + textScaler.scale(12) * 1.5,
              ),
              itemCount: QrType.values.length,
              itemBuilder: (context, i) {
                final type = QrType.values[i];
                return _TypeTile(
                  type: type,
                  textScaler: textScaler,
                  onTap: () => _open(context, QrEditorPage(type: type)),
                );
              },
            ),
          ),
        ),
        const _SectionHeader(title: 'Photo post'),
        _Group(
          child: _RowTile(
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(
                Icons.format_quote_rounded,
                color: colorScheme.primary,
              ),
            ),
            title: 'Text on a photo',
            subtitle: 'Add a quote or caption, then share it to your socials',
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => _open(context, const PostEditorPage()),
          ),
        ),
        _SectionHeader(
          title: 'My codes',
          trailing: codes.isEmpty
              ? null
              : Text(
                  '${codes.length}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        if (provider.isLoading && codes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (provider.error != null && codes.isEmpty)
          Text(provider.error!, style: TextStyle(color: colorScheme.error))
        else if (codes.isEmpty)
          const _EmptyCodes()
        else
          _Group(
            child: Column(
              children: [
                for (var i = 0; i < codes.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 74,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  _CodeRow(
                    code: codes[i],
                    onTap: () =>
                        _open(context, QrEditorPage.edit(code: codes[i])),
                    onLongPress: () => _actions(context, codes[i]),
                    onDismissed: () => _delete(context, codes[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Rounded white group, as in Scans and Settings.
class _Group extends StatelessWidget {
  final Widget child;
  const _Group({required this.child});

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class _RowTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _RowTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final QrType type;
  final TextScaler textScaler;
  final VoidCallback onTap;

  const _TypeTile({
    required this.type,
    required this.textScaler,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: type.color.withValues(alpha: 0.12),
              child: Icon(type.icon, color: type.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: textScaler,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCodes extends StatelessWidget {
  const _EmptyCodes();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Group(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.qr_code_2,
              size: 44,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Codes you save appear here, ready to share again or edit.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeRow extends StatelessWidget {
  final CreatedCode code;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDismissed;

  const _CodeRow({
    required this.code,
    required this.onTap,
    required this.onLongPress,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('code-${code.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.white),
          ],
        ),
      ),
      child: _RowTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: StyledQr(
            data: code.data,
            style: code.style,
            size: 40,
            showCaption: false,
          ),
        ),
        title: QrEncoder.summary(code.type, code.fields),
        subtitle:
            '${code.type.label} · ${dayLabel(code.updatedAt)} '
            '${timeLabel(code.updatedAt)}',
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
