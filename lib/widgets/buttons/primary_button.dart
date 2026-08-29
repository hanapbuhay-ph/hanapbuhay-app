import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Reusable Primary Button matching the Stitch design.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showArrow;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.showArrow = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: width ?? double.infinity,
        constraints: width == null ? const BoxConstraints(maxWidth: 400) : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primary : AppColors.disabled,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: isLoading 
          ? const Center(
              child: SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: isEnabled ? Colors.white : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (showArrow) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: isEnabled ? Colors.white : AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ],
            ),
      ),
    );
  }
}
