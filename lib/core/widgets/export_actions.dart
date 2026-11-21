import 'package:material_ui/material_ui.dart';

/// Save / Gallery / Share row shared by the QR maker and the photo post
/// editor. Labels shrink rather than wrap on narrow screens.
class ExportActions extends StatelessWidget {
  /// Height of the row, for layouts that reserve space for it.
  static const double height = 52;

  final bool canAct;
  final bool unchanged;
  final VoidCallback? onSave;
  final VoidCallback onGallery;
  final VoidCallback onShare;

  const ExportActions({
    super.key,
    required this.canAct,
    required this.unchanged,
    required this.onSave,
    required this.onGallery,
    required this.onShare,
  });

  static const _compact = ButtonStyle(
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 10, vertical: 14),
    ),
  );

  Widget _label(String text) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: _compact,
            onPressed: canAct && !unchanged ? onSave : null,
            icon: Icon(
              unchanged ? Icons.check : Icons.bookmark_add_outlined,
              size: 20,
            ),
            label: _label(unchanged ? 'Saved' : 'Save'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            style: _compact,
            onPressed: canAct ? onGallery : null,
            icon: const Icon(Icons.download_outlined, size: 20),
            label: _label('Gallery'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            style: _compact,
            onPressed: canAct ? onShare : null,
            icon: const Icon(Icons.share_outlined, size: 20),
            label: _label('Share'),
          ),
        ),
      ],
    );
  }
}

/// The bottom bar that holds [ExportActions] on phones.
class ExportActionBar extends StatelessWidget {
  final Widget child;
  const ExportActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
