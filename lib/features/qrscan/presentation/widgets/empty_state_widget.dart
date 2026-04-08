// lib/features/qrscan/presentation/widgets/empty_state_widget.dart
import 'package:flutter/material.dart';

enum EmptyStateType { noScans, noSearchResults, noHistory, general }

class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  const EmptyStateWidget({
    super.key,
    required this.type,
    this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getEmptyStateConfig(context);

    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: config.iconBackgroundColor,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon ?? config.defaultIcon,
                size: config.iconSize,
                color: config.iconColor,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              title ?? config.defaultTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: config.titleColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              subtitle ?? config.defaultSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: config.subtitleColor),
              textAlign: TextAlign.center,
            ),

            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }

  _EmptyStateConfig _getEmptyStateConfig(BuildContext context) {
    switch (type) {
      case EmptyStateType.noScans:
        return _EmptyStateConfig(
          defaultIcon: Icons.qr_code_2,
          iconSize: 48,
          iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          iconBackgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          titleColor: Theme.of(context).colorScheme.onSurface,
          subtitleColor: Theme.of(context).colorScheme.onSurfaceVariant,
          defaultTitle: 'No scans yet',
          defaultSubtitle: 'Scan your first QR code to get started',
        );

      case EmptyStateType.noSearchResults:
        return _EmptyStateConfig(
          defaultIcon: Icons.search_off,
          iconSize: 32,
          iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          iconBackgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          titleColor: Theme.of(context).colorScheme.onSurface,
          subtitleColor: Theme.of(context).colorScheme.onSurfaceVariant,
          defaultTitle: 'No scans found',
          defaultSubtitle: 'Try adjusting your search terms',
        );

      case EmptyStateType.noHistory:
        return _EmptyStateConfig(
          defaultIcon: Icons.history,
          iconSize: 48,
          iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          iconBackgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          titleColor: Theme.of(context).colorScheme.onSurface,
          subtitleColor: Theme.of(context).colorScheme.onSurfaceVariant,
          defaultTitle: 'No scan history',
          defaultSubtitle: 'Your scanned QR codes will appear here',
        );

      case EmptyStateType.general:
        return _EmptyStateConfig(
          defaultIcon: Icons.inbox,
          iconSize: 48,
          iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          iconBackgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          titleColor: Theme.of(context).colorScheme.onSurface,
          subtitleColor: Theme.of(context).colorScheme.onSurfaceVariant,
          defaultTitle: 'Nothing here',
          defaultSubtitle: 'This area is empty',
        );
    }
  }
}

class _EmptyStateConfig {
  final IconData defaultIcon;
  final double iconSize;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final String defaultTitle;
  final String defaultSubtitle;

  _EmptyStateConfig({
    required this.defaultIcon,
    required this.iconSize,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.defaultTitle,
    required this.defaultSubtitle,
  });
}
