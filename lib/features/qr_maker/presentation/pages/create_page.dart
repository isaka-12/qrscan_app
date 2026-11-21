import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/created_code.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/qr_encoder.dart';
import '../providers/qr_maker_provider.dart';
import '../widgets/styled_qr.dart';
import 'qr_editor_page.dart';

/// The Create tab: pick a QR type to make, and reopen saved codes.
class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QrMakerProvider>();
    final codes = provider.codes;
    final colorScheme = Theme.of(context).colorScheme;
    // Tiles grow with the system font size, up to a point.
    final textScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.3);

    return LayoutBuilder(
      builder: (context, constraints) {
        final inner = constraints.maxWidth - 32;
        final codeColumns = inner >= 560 ? 2 : 1;
        final codeWidth = (inner - 12 * (codeColumns - 1)) / codeColumns;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const _SectionHeader(title: 'New QR code'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // ~4 per row on phones, all 7 in one row on tablets.
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 100,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 76 + textScaler.scale(12) * 1.5,
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
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'My codes',
              trailing: codes.isEmpty
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${codes.length}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
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
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final code in codes)
                    SizedBox(
                      width: codeWidth,
                      child: _CodeCard(
                        code: code,
                        onTap: () =>
                            _open(context, QrEditorPage.edit(code: code)),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
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
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(type.icon, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: textScaler,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_2,
            size: 48,
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
    );
  }
}

class _CodeCard extends StatelessWidget {
  final CreatedCode code;
  final VoidCallback onTap;

  const _CodeCard({required this.code, required this.onTap});

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<QrMakerProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete this code?'),
        content: const Text(
          'It will be removed from My codes. Images you already saved or '
          'shared are not affected.',
        ),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && code.id != null) await provider.delete(code.id!);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: StyledQr(
              data: code.data,
              style: code.style,
              size: 44,
              showCaption: false,
            ),
          ),
          title: Text(
            QrEncoder.summary(code.type, code.fields),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            '${code.type.label} · ${_formatDate(code.updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) => v == 'edit' ? onTap() : _confirmDelete(context),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final day = DateTime(local.year, local.month, local.day);
    final today = DateTime(now.year, now.month, now.day);
    final time = local.toString().substring(11, 16);
    if (day == today) return 'Today $time';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday $time';
    }
    return local.toString().substring(0, 10);
  }
}
