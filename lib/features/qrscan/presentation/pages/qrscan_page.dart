// lib/features/qrscan/presentation/pages/qrscan_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/location_helper.dart';

import '../../domain/entities/scan.dart';
import '../providers/qrscan_provider.dart';
import '../widgets/qr_data_display.dart';
import '../widgets/scan_details_dialog.dart';
import '../widgets/status_container_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/scan_card_widget.dart';

class QrScanPage extends StatefulWidget {
  final VoidCallback? onViewAllTapped;

  const QrScanPage({super.key, this.onViewAllTapped});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  MobileScannerController? controller;
  bool isScanning = false;
  bool isProcessingScan = false;

  void _startScanning() async {
    setState(() {
      isScanning = true;
    });

    controller = MobileScannerController();
    await _showScannerDialog();
  }

  Future<void> _showScannerDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 450,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),

          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.appBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: AppTheme.appBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scan QR Code',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.appGold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.appBlue.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    padding: EdgeInsets.all(1),
                    onPressed: _stopScanning,
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.appBlue,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: MobileScanner(
                      controller: controller!,
                      onDetect: _onQrDetected,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Position the QR code within the frame',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.appGrey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQrDetected(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && mounted) {
      final provider = context.read<QrScanProvider>();

      _stopScanning();

      // Show processing state
      setState(() {
        isProcessingScan = true;
      });

      try {
        final (lat, lng, address) = await LocationHelper.getCurrentLocation();

        final scan = Scan(
          qrData: barcodes.first.displayValue ?? "Unknown",
          timestamp: DateTime.now(),
          latitude: lat,
          longitude: lng,
          address: address,
        );

        // Save to database and update UI immediately
        await provider.addScan(scan);

        // Processing completed successfully
        setState(() {
          isProcessingScan = false;
        });

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.primaryTextDark),
                  const SizedBox(width: 8),
                  const Text('QR code scanned successfully!'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          isProcessingScan = false;
        });
        // Show error snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: AppTheme.primaryTextDark),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Error processing scan: $e')),
                ],
              ),
              backgroundColor: AppTheme.appError,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  void _stopScanning() {
    if (controller != null) {
      controller!.dispose();
      controller = null;
    }
    setState(() {
      isScanning = false;
    });
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showScanDetails(Scan scan) {
    ScanDetailsDialog.show(context: context, scan: scan);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QrScanProvider>();

    return Scaffold(
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Processing state
                if (isProcessingScan)
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
                      color: AppTheme.accentLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successColor.withOpacity(0.1),
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
                                color: AppTheme.successColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryTextDark,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Latest Scan Result',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                            const Spacer(),

                            IconButton(
                              onPressed: () =>
                                  _showScanDetails(provider.scans.first),
                              icon: const Icon(
                                Icons.info_outline,
                                color: AppTheme.appBlue,
                                size: 20,
                              ),
                              tooltip: 'View Details',
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.surfaceLight,
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
                            color: Theme.of(context).colorScheme.surface,
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
                                    color: AppTheme.appGrey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    provider.scans.first.timestamp
                                        .toLocal()
                                        .toString()
                                        .substring(0, 19),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppTheme.appGrey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 18,
                                    color: AppTheme.appGrey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      provider.scans.first.address,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppTheme.appGrey),
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (provider.scans.length > 3)
                          TextButton(
                            onPressed: widget.onViewAllTapped,
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
                          onTap: () => _showScanDetails(scan),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isScanning ? null : _startScanning,
        icon: isScanning
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.qr_code_scanner),
        label: Text(isScanning ? 'Scanning...' : 'Scan QR'),
      ),
    );
  }
}
