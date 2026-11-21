// lib/features/qrscan/presentation/pages/qrscan_page.dart
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/scan.dart';
import '../providers/qrscan_provider.dart';
import '../widgets/qr_data_display.dart';
import '../widgets/scan_details_dialog.dart';
import '../widgets/status_container_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/scan_card_widget.dart';

/// The Home tab: latest scan (or a welcome), quick actions, recent scans.
/// Everything scrolls, so it also fits short landscape screens.
class QrScanPage extends StatelessWidget {
  final VoidCallback? onViewAllTapped;
  final VoidCallback? onScanTapped;
  final VoidCallback? onCreateTapped;

  const QrScanPage({
    super.key,
    this.onViewAllTapped,
    this.onScanTapped,
    this.onCreateTapped,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QrScanProvider>();
    final textTheme = Theme.of(context).textTheme;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final recent = provider.scans.take(3).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (provider.isProcessingScan)
          const StatusContainerWidget(
            type: StatusType.processing,
            title: 'Processing scan...',
            subtitle: 'Getting location and saving data',
            showLoadingIndicator: true,
          )
        else if (provider.scans.isNotEmpty)
          _LatestScanCard(scan: provider.scans.first)
        else
          const StatusContainerWidget(
            type: StatusType.welcome,
            title: 'Welcome to Locus',
            subtitle:
                'Scan QR codes and keep them with time and place, '
                'or create your own to share.',
            icon: Icons.qr_code_scanner,
          ),

        // Quick actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan',
                  subtitle: 'Read a code',
                  onTap: onScanTapped,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.add_box_outlined,
                  title: 'Create',
                  subtitle: 'Make your own',
                  onTap: onCreateTapped,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Recent scans
        if (recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent scans',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (provider.scans.length > recent.length)
                  TextButton(
                    onPressed: onViewAllTapped,
                    child: const Text('View all'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final scan in recent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ScanCardWidget(
                scan: scan,
                onTap: () =>
                    ScanDetailsDialog.show(context: context, scan: scan),
                showFullDate: true,
              ),
            ),
        ] else
          const EmptyStateWidget(
            type: EmptyStateType.noScans,
            padding: EdgeInsets.fromLTRB(32, 16, 32, 32),
          ),
      ],
    );
  }
}

class _LatestScanCard extends StatelessWidget {
  final Scan scan;
  const _LatestScanCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Latest scan',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    ScanDetailsDialog.show(context: context, scan: scan),
                icon: Icon(
                  Icons.info_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
                tooltip: 'View details',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QRDataDisplay(qrData: scan.qrData),
                const SizedBox(height: 16),
                _MetaRow(
                  icon: Icons.access_time,
                  text: scan.timestamp.toLocal().toString().substring(0, 19),
                ),
                const SizedBox(height: 8),
                _MetaRow(icon: Icons.location_on, text: scan.address),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
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
