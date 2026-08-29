import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'app_back_button.dart';

/// Standardized Header for registration and authentication screens.
/// 
/// Ensures the back button and logo text are positioned identically
/// across all screens in the flow.
class AppHeader extends StatelessWidget {
  final bool showBackButton;
  final String title;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;

  const AppHeader({
    super.key,
    this.showBackButton = true,
    this.title = 'HanapBuhay',
    this.onBackPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (showBackButton)
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppBackButton(onPressed: onBackPressed),
                ),
              Text(
                title,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
