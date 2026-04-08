import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/scan.dart';

// Widget to display a scan card with QR data, timestamp, and address.
class ScanCardWidget extends StatelessWidget {
  final Scan scan;
  final VoidCallback? onTap;
  final bool showFullDate;
  final EdgeInsetsGeometry? margin;

  const ScanCardWidget({
    super.key,
    required this.scan,
    this.onTap,
    this.showFullDate = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(scan.timestamp);

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isToday
                ? AppTheme.successColor.withOpacity(0.1)
                : AppTheme.appBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.qr_code,
            color: isToday ? AppTheme.successColor : AppTheme.appBlue,
            size: 20,
          ),
        ),
        title: Text(
          scan.qrData,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  showFullDate
                      ? _formatFullDateTime(scan.timestamp)
                      : _formatDateTime(scan.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    scan.address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scanDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (scanDate == today) {
      return 'Today ${dateTime.toLocal().toString().substring(11, 16)}';
    } else if (scanDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${dateTime.toLocal().toString().substring(11, 16)}';
    } else {
      return dateTime.toLocal().toString().substring(0, 16);
    }
  }

  String _formatFullDateTime(DateTime dateTime) {
    return dateTime.toLocal().toString().substring(0, 19);
  }
}
