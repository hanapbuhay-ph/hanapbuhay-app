import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        background: AppColors.background,
        onBackground: AppColors.onSurface,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceVariant: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
      ),
      fontFamily: AppTypography.fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.primary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.onSurface),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.onSurface),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.onSurface),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.onSurface),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.onSurface),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.primary),
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimaryContainer: AppColors.darkOnPrimaryContainer,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnSecondary,
        secondaryContainer: AppColors.darkSecondaryContainer,
        onSecondaryContainer: AppColors.darkOnSecondaryContainer,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkOnBackground,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        surfaceVariant: AppColors.darkSurfaceVariant,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        outline: AppColors.darkOutline,
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
        errorContainer: AppColors.darkErrorContainer,
        onErrorContainer: AppColors.darkOnErrorContainer,
      ),
      fontFamily: AppTypography.fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.darkPrimary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.darkOnSurface),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.darkOnSurface),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.darkOnSurface),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkOnSurface),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnSurface),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.darkOnSurfaceVariant),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.darkOnSurface),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.darkPrimary),
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
    );
  }
}
