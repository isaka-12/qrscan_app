import 'package:flutter/material.dart';
import 'package:qrscan_app/core/theme/app_theme.dart';

class DetailRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelectable;
  final IconData? icon;
  final Color? labelColor;
  final Color? valueColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final EdgeInsetsGeometry? padding;

  const DetailRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.isSelectable = false,
    this.icon,
    this.labelColor,
    this.valueColor,
    this.labelStyle,
    this.valueStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final defaultLabelColor = labelColor ?? AppTheme.appGold;
    final defaultValueColor = valueColor ?? AppTheme.appDarkGrey;

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: defaultLabelColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style:
                    labelStyle ??
                    Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: defaultLabelColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          isSelectable
              ? SelectableText(
                  value,
                  style:
                      valueStyle ??
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: defaultValueColor,
                      ),
                )
              : Text(
                  value,
                  style:
                      valueStyle ??
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: defaultValueColor,
                      ),
                ),
        ],
      ),
    );
  }
}
