import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final double opacity;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    final content = Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(20),
      ),
      child: icon == null
          ? content
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                content,
              ],
            ),
    );
  }
}
