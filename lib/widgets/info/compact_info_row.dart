import 'package:flutter/material.dart';

class CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const CompactInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultLabelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        );
    final defaultValueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 10,
          color: colorScheme.onSurfaceVariant,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor ?? colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle ?? defaultLabelStyle),
              Text(value, style: valueStyle ?? defaultValueStyle),
            ],
          ),
        ),
      ],
    );
  }
}
