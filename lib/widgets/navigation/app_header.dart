import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    
    return Container(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (showBackButton) ...[
                AppBackButton(onPressed: onBackPressed),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineMedium.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
