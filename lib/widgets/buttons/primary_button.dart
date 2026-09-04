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
    
    final effectiveBackgroundColor = backgroundColor ?? colorScheme.primary;
    final contentColor = foregroundColor ?? colorScheme.onPrimary;

    final button = ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: contentColor,
        disabledBackgroundColor: colorScheme.surfaceContainerHighest,
        disabledForegroundColor: colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isEnabled ? 2 : 0,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: contentColor, strokeWidth: 2),
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
                  Icon(Icons.arrow_forward, color: contentColor, size: 20),
                ],
              ],
            ),
    );

    final sizedButton = SizedBox(
      width: width ?? double.infinity,
      child: button,
    );

    return width == null
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: sizedButton,
          )
        : sizedButton;
  }
}
