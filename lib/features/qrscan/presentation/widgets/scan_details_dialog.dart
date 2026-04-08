// lib/features/qrscan/presentation/widgets/scan_details_dialog.dart
import 'package:flutter/material.dart';

import '../../domain/entities/scan.dart';
import 'detail_row_widget.dart';
import 'qr_data_display.dart';

class ScanDetailsDialog extends StatelessWidget {
  final Scan scan;
  final String? title;
  final List<Widget>? additionalActions;

  const ScanDetailsDialog({
    super.key,
    required this.scan,
    this.title,
    this.additionalActions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.qr_code,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title ?? 'QR Code Details',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Data Display
            QRDataDisplay(qrData: scan.qrData),

            const SizedBox(height: 20),

            // Scan Details
            DetailRowWidget(
              label: 'Scanned At:',
              value: scan.timestamp.toLocal().toString().substring(0, 19),
              icon: Icons.access_time,
            ),

            const SizedBox(height: 12),

            DetailRowWidget(
              label: 'Location:',
              value: scan.address,
              icon: Icons.location_on,
              isSelectable: true,
            ),

            const SizedBox(height: 12),

            DetailRowWidget(
              label: 'Coordinates:',
              value:
                  '${scan.latitude.toStringAsFixed(6)}, ${scan.longitude.toStringAsFixed(6)}',
              icon: Icons.my_location,
              isSelectable: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required Scan scan,
    String? title,
    List<Widget>? additionalActions,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ScanDetailsDialog(
        scan: scan,
        title: title,
        additionalActions: additionalActions,
      ),
    );
  }
}
