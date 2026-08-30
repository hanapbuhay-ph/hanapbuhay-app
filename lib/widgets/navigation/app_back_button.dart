import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A reusable glass-themed back button in a circle container.
/// 
/// Reused across all screens (Role Selection, Registration, etc.) 
/// to maintain a consistent UI structure.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (color ?? AppColors.primary).withOpacity(0.12),
            border: Border.all(
              color: (color ?? AppColors.primary).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed ?? () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: color ?? AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
