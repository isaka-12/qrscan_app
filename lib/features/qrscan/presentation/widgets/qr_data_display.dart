import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qrscan_app/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';



enum QRDataType { text, url, imageUrl, email, phone, wifi, coordinates }

class QRDataDisplay extends StatelessWidget {
  final String qrData;
  final bool isCompact;

  const QRDataDisplay({
    super.key,
    required this.qrData,
    this.isCompact = false,
  });

  QRDataType _getDataType(String data) {
    if (data.isEmpty) return QRDataType.text;

    final String lowerData = data.toLowerCase().trim();

    // Check for URL
    if (lowerData.startsWith('http://') ||
        lowerData.startsWith('https://') ||
        lowerData.startsWith('www.')) {
      // Check for image URLs
      if (lowerData.contains('.jpg') ||
          lowerData.contains('.jpeg') ||
          lowerData.contains('.png') ||
          lowerData.contains('.gif') ||
          lowerData.contains('.webp') ||
          lowerData.contains('.bmp')) {
        return QRDataType.imageUrl;
      }

      return QRDataType.url;
    }

    // Check for email
    if (lowerData.contains('@') && lowerData.contains('.')) {
      return QRDataType.email;
    }

    // Check for phone number
    if (RegExp(r'^[\+]?[0-9\s\-\(\)]+$').hasMatch(data.trim())) {
      return QRDataType.phone;
    }

    // Check for WiFi configuration
    if (lowerData.startsWith('wifi:')) {
      return QRDataType.wifi;
    }

    // Check for coordinates (latitude,longitude)
    if (RegExp(
      r'^-?[0-9]+\.?[0-9]*,-?[0-9]+\.?[0-9]*$',
    ).hasMatch(data.trim())) {
      return QRDataType.coordinates;
    }

    return QRDataType.text;
  }

  IconData _getIcon(String data) {
    final dataType = _getDataType(data);

    switch (dataType) {
      case QRDataType.url:
        return Icons.link;
      case QRDataType.imageUrl:
        return Icons.image;
      case QRDataType.email:
        return Icons.email;
      case QRDataType.phone:
        return Icons.phone;
      case QRDataType.wifi:
        return Icons.wifi;
      case QRDataType.coordinates:
        return Icons.location_on;
      default:
        return Icons.text_fields;
    }
  }

  String _getTypeDescription(String data) {
    final dataType = _getDataType(data);

    switch (dataType) {
      case QRDataType.url:
        return 'Website Link';
      case QRDataType.imageUrl:
        return 'Image Link';
      case QRDataType.email:
        return 'Email Address';
      case QRDataType.phone:
        return 'Phone Number';
      case QRDataType.wifi:
        return 'WiFi Configuration';
      case QRDataType.coordinates:
        return 'Coordinates';
      default:
        return 'Text';
    }
  }

  bool _isActionable(String data) {
    final dataType = _getDataType(data);
    return dataType != QRDataType.text;
  }

  Future<bool> _launchData(String data) async {
    try {
      final dataType = _getDataType(data);
      String? url;

      switch (dataType) {
        case QRDataType.url:
        case QRDataType.imageUrl:
          url = data.startsWith('http') ? data : 'https://$data';
          break;
        case QRDataType.email:
          url = 'mailto:$data';
          break;
        case QRDataType.phone:
          url = 'tel:${data.replaceAll(RegExp(r'[^\d\+]'), '')}';
          break;
        case QRDataType.coordinates:
          final coords = data.split(',');
          if (coords.length == 2) {
            url = 'https://maps.google.com/?q=${coords[0]},${coords[1]}';
          }
          break;
        default:
          return false;
      }

      if (url != null) {
        final uri = Uri.parse(url);
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataType = _getDataType(qrData);
    final isActionable = _isActionable(qrData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Data type header
        Row(
          children: [
            Icon(
              _getIcon(qrData),
              size: isCompact ? 16 : 18,
              color: AppTheme.appBlue,
            ),
            const SizedBox(width: 6),
            Text(
              _getTypeDescription(qrData),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.appBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isActionable) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.appAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'TAP TO OPEN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.appAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Display content based on type
        if (dataType == QRDataType.imageUrl && !isCompact)
          _buildImageDisplay(context)
        else
          _buildTextDisplay(context, isActionable),
      ],
    );
  }

  Widget _buildImageDisplay(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.appLightGrey),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: CachedNetworkImage(
              imageUrl: qrData,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppTheme.appLightGrey,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.appBlue),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppTheme.appLightGrey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      size: 48,
                      color: AppTheme.appGrey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: AppTheme.appGrey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTextDisplay(context, true),
      ],
    );
  }

  Widget _buildTextDisplay(BuildContext context, bool isActionable) {
    return InkWell(
      onTap: isActionable ? () => _handleTap(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActionable
              ? AppTheme.appBlue.withOpacity(0.05)
              : AppTheme.appLightGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActionable
                ? AppTheme.appBlue.withOpacity(0.2)
                : AppTheme.appLightGrey,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: SelectableText(
                qrData,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isActionable
                      ? AppTheme.appBlue
                      : AppTheme.appDarkGrey,
                  fontWeight: isActionable ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            if (isActionable) ...[
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, size: 18, color: AppTheme.appBlue),
            ],
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) async {
    final success = await _launchData(qrData);
    if (!success) {
      // Show error message if launching fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: AppTheme.primaryTextDark),
              const SizedBox(width: 8),
              const Text('Unable to open this content'),
            ],
          ),
          backgroundColor: AppTheme.appError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

// Global navigator key to access context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
