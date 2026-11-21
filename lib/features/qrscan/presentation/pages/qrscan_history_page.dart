import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/scan.dart';
import '../providers/qrscan_provider.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/scan_details_dialog.dart';
import '../widgets/scan_kind.dart';

/// The Scans tab (home): search, then scans grouped by day in rounded list
/// groups. Swipe left to delete (with Undo); long-press for more actions.
class QrScanHistoryPage extends StatefulWidget {
  const QrScanHistoryPage({super.key});

  @override
  State<QrScanHistoryPage> createState() => _QrScanHistoryPageState();
}

class _QrScanHistoryPageState extends State<QrScanHistoryPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Scan s) =>
      s.qrData.toLowerCase().contains(_query) ||
      s.address.toLowerCase().contains(_query) ||
      ScanKind.of(s.qrData).title.toLowerCase().contains(_query);

  Future<void> _delete(Scan scan) async {
    final provider = context.read<QrScanProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final index = await provider.deleteScan(scan);
      if (index < 0) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Scan deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => provider.restoreScan(scan, index),
            ),
          ),
        );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }

  Future<void> _actions(Scan scan) async {
    final kind = ScanKind.of(scan.qrData);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _KindAvatar(kind: kind),
              title: Text(
                kind.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${kind.label} · ${dayLabel(scan.timestamp)} '
                '${timeLabel(scan.timestamp)}',
              ),
            ),
            const Divider(height: 8),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Details'),
              onTap: () => Navigator.pop(ctx, 'details'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy'),
              onTap: () => Navigator.pop(ctx, 'copy'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () => Navigator.pop(ctx, 'share'),
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
    if (!mounted) return;
    switch (action) {
      case 'details':
        ScanDetailsDialog.show(context: context, scan: scan);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: scan.qrData));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Copied')));
        }
      case 'share':
        await SharePlus.instance.share(ShareParams(text: scan.qrData));
      case 'delete':
        await _delete(scan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QrScanProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (provider.isLoading && provider.scans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.scans.isEmpty) {
      return const EmptyStateWidget(type: EmptyStateType.noHistory);
    }

    final scans = _query.isEmpty
        ? provider.scans
        : provider.scans.where(_matches).toList();

    // Group consecutive scans (already newest first) by day.
    final groups = <String, List<Scan>>{};
    for (final s in scans) {
      groups.putIfAbsent(dayLabel(s.timestamp), () => []).add(s);
    }

    return ListView(
      // Bottom room so the Scan button never covers the last scan.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
      children: [
        _SearchField(controller: _search),
        if (_query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
            child: Text(
              scans.isEmpty
                  ? 'No scans match "${_search.text.trim()}"'
                  : '${scans.length} result${scans.length == 1 ? '' : 's'}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Text(
              entry.key,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Material(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < entry.value.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  _ScanRow(
                    scan: entry.value[i],
                    onTap: () => ScanDetailsDialog.show(
                      context: context,
                      scan: entry.value[i],
                    ),
                    onLongPress: () => _actions(entry.value[i]),
                    onDismissed: () => _delete(entry.value[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search scans',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: controller.clear,
                ),
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _KindAvatar extends StatelessWidget {
  final ScanKind kind;
  const _KindAvatar({required this.kind});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 22,
    backgroundColor: kind.color.withValues(alpha: 0.14),
    child: Icon(kind.icon, color: kind.color, size: 22),
  );
}

class _ScanRow extends StatelessWidget {
  final Scan scan;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDismissed;

  const _ScanRow({
    required this.scan,
    required this.onTap,
    required this.onLongPress,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final kind = ScanKind.of(scan.qrData);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey(
        '${scan.timestamp.microsecondsSinceEpoch}|${scan.qrData.hashCode}',
      ),
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
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              _KindAvatar(kind: kind),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${kind.label} · ${timeLabel(scan.timestamp)} · '
                      '${scan.address}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
