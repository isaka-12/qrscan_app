// lib/features/qrscan/presentation/widgets/status_container_widget.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

enum StatusType { processing, success, welcome, error, warning }

class StatusContainerWidget extends StatelessWidget {
  final StatusType type;
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool showLoadingIndicator;
  final List<Widget>? additionalActions;

  const StatusContainerWidget({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    this.icon,
    this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.showLoadingIndicator = false,
    this.additionalActions,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(context);

    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.all(16),
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusConfig.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusConfig.shadowColor.withOpacity(0.1),
            blurRadius: statusConfig.type == StatusType.welcome ? 15 : 10,
            offset: Offset(0, statusConfig.type == StatusType.welcome ? 6 : 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            if (showLoadingIndicator || icon != null)
              Container(
                padding: EdgeInsets.all(
                  statusConfig.type == StatusType.welcome ? 16 : 12,
                ),
                decoration: BoxDecoration(
                  color: statusConfig.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: showLoadingIndicator
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusConfig.iconColor,
                          ),
                        ),
                      )
                    : Icon(
                        icon ?? statusConfig.defaultIcon,
                        size: statusConfig.type == StatusType.welcome
                            ? 48.0
                            : 24.0,
                        color: statusConfig.iconColor,
                      ),
              ),

            if (showLoadingIndicator || icon != null)
              SizedBox(
                height: statusConfig.type == StatusType.welcome ? 20.0 : 16.0,
              ),

            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: statusConfig.titleColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: statusConfig.subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),

            if (child != null) ...[const SizedBox(height: 16), child!],

            if (additionalActions != null && additionalActions!.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...additionalActions!,
            ],
          ],
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(BuildContext context) {
    switch (type) {
      case StatusType.processing:
        return _StatusConfig(
          type: type,
          backgroundColor: AppTheme.warningLight,
          shadowColor: AppTheme.warningColor,
          iconBackgroundColor: AppTheme.warningColor.withOpacity(0.1),
          iconColor: AppTheme.warningDark,
          titleColor: AppTheme.warningDark,
          subtitleColor: AppTheme.warningDark.withOpacity(0.8),
          defaultIcon: Icons.hourglass_empty,
        );

      case StatusType.success:
        return _StatusConfig(
          type: type,
          backgroundColor: AppTheme.successLight,
          shadowColor: AppTheme.successColor,
          iconBackgroundColor: AppTheme.successColor,
          iconColor: AppTheme.primaryTextDark,
          titleColor: AppTheme.successDark,
          subtitleColor: AppTheme.successDark.withOpacity(0.8),
          defaultIcon: Icons.check_circle,
        );

      case StatusType.welcome:
        return _StatusConfig(
          type: type,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shadowColor: Theme.of(context).primaryColor,
          iconBackgroundColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withOpacity(0.2),
          iconColor: Theme.of(context).colorScheme.onPrimary,
          titleColor: Theme.of(context).colorScheme.onPrimary,
          subtitleColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withOpacity(0.9),
          defaultIcon: Icons.qr_code_scanner,
        );

      case StatusType.error:
        return _StatusConfig(
          type: type,
          backgroundColor: AppTheme.appError.withOpacity(0.1),
          shadowColor: AppTheme.appError,
          iconBackgroundColor: AppTheme.appError.withOpacity(0.1),
          iconColor: AppTheme.appError,
          titleColor: AppTheme.appError,
          subtitleColor: AppTheme.appError.withOpacity(0.8),
          defaultIcon: Icons.error_outline,
        );

      case StatusType.warning:
        return _StatusConfig(
          type: type,
          backgroundColor: AppTheme.warningLight,
          shadowColor: AppTheme.warningColor,
          iconBackgroundColor: AppTheme.warningColor.withOpacity(0.1),
          iconColor: AppTheme.warningColor,
          titleColor: AppTheme.warningDark,
          subtitleColor: AppTheme.warningDark.withOpacity(0.8),
          defaultIcon: Icons.warning_amber_outlined,
        );
    }
  }
}

class _StatusConfig {
  final StatusType type;
  final Color? backgroundColor;
  final Color shadowColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final IconData defaultIcon;

  _StatusConfig({
    required this.type,
    this.backgroundColor,
    required this.shadowColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.defaultIcon,
  });
}
