import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

/// Reusable Primary Button matching the Stitch design.
/// Updated with backgroundColor support.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showArrow;
  final double? width;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.showArrow = false,
    this.width,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isEnabled = onPressed != null && !isLoading;
    
    final effectiveBackgroundColor = backgroundColor ?? (isEnabled ? colorScheme.primary : colorScheme.surfaceVariant);
    final contentColor = foregroundColor ?? (isEnabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant);

    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: width ?? double.infinity,
        constraints: width == null ? const BoxConstraints(maxWidth: 400) : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: effectiveBackgroundColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: isLoading 
          ? Center(
              child: SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(color: contentColor, strokeWidth: 2)
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (showArrow) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: contentColor,
                    size: 20,
                  ),
                ],
              ],
            ),
      ),
    );
  }
}
