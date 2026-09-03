import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_typography.dart';

/// Reusable Google Sign-In Button.
/// 
/// Uses a local asset 'assets/icons/google.svg'.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.label = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: SvgPicture.asset('assets/icon/google.svg', height: 24),
        label: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          backgroundColor: colorScheme.surfaceContainerLowest,
          disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(
            color: isEnabled ? colorScheme.outlineVariant : colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
          elevation: isEnabled ? 1 : 0,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
