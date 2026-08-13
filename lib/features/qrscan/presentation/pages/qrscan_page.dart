// lib/features/qrscan/presentation/pages/qrscan_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/qrscan_provider.dart';
import '../widgets/qr_data_display.dart';
import '../widgets/scan_details_dialog.dart';
import '../widgets/status_container_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/scan_card_widget.dart';

class QrScanPage extends StatelessWidget {
  final VoidCallback? onViewAllTapped;

  const QrScanPage({super.key, this.onViewAllTapped});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QrScanProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Processing state
                if (provider.isProcessingScan)
                  StatusContainerWidget(
                    type: StatusType.processing,
                    title: 'Processing scan...',
                    subtitle: 'Getting location and saving data',
                    showLoadingIndicator: true,
                  )
                // Latest scan result
                else if (provider.scans.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: colorScheme.onPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Latest Scan Result',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => ScanDetailsDialog.show(
                                context: context,
                                scan: provider.scans.first,
                              ),
                              icon: Icon(
                                Icons.info_outline,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              tooltip: 'View Details',
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              QRDataDisplay(
                                qrData: provider.scans.first.qrData,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    provider.scans.first.timestamp
                                        .toLocal()
                                        .toString()
                                        .substring(0, 19),
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      provider.scans.first.address,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                // Welcome section (when no scan yet)
                else
                  StatusContainerWidget(
                    type: StatusType.welcome,
                    title: 'Welcome to QR Scanner',
                    subtitle: 'Tap the scan button to start scanning QR codes',
                    icon: Icons.qr_code_scanner,
                  ),

                // Recent scans section
                if (provider.scans.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Scans',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (provider.scans.length > 3)
                          TextButton(
                            onPressed: onViewAllTapped,
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.scans.length > 3
                          ? 3
                          : provider.scans.length,
                      itemBuilder: (context, index) {
                        final scan = provider.scans[index];
                        return ScanCardWidget(
                          scan: scan,
                          onTap: () => ScanDetailsDialog.show(
                            context: context,
                            scan: scan,
                          ),
                          showFullDate: true,
                        );
                      },
                    ),
                  ),
                ] else
                  const Expanded(
                    child: EmptyStateWidget(type: EmptyStateType.noScans),
                  ),
              ],
            ),
    );
  }
}
