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
        surface: AppColors.darkSurfaceContainer,
        surfaceContainerLowest: AppColors.darkSurfaceContainerLowest,
        surfaceContainerLow: AppColors.darkSurfaceContainerLow,
        surfaceContainer: AppColors.darkSurfaceContainer,
        surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
        surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
        onSurface: AppColors.darkOnSurface,
        surfaceVariant: AppColors.darkSurfaceVariant,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        outline: AppColors.darkOutline,
        outlineVariant: AppColors.darkOutlineVariant,
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
        errorContainer: AppColors.darkErrorContainer,
        onErrorContainer: AppColors.darkOnErrorContainer,
      ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurfaceContainer,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.darkOutlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.darkOutlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
          ),
          hintStyle: TextStyle(color: AppColors.darkOnSurfaceVariant),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.darkSurfaceContainer,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.darkSurfaceContainer,
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: const DividerThemeData(color: AppColors.darkOutline),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkPrimary,
            foregroundColor: AppColors.darkOnPrimary,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkPrimary,
            side: const BorderSide(color: AppColors.darkOutline),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(AppColors.darkPrimary),
            overlayColor: WidgetStateProperty.all(AppColors.darkPrimary.withValues(alpha: 0.12)),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(AppColors.darkOnSurfaceVariant),
            overlayColor: WidgetStateProperty.all(AppColors.darkPrimary.withValues(alpha: 0.12)),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkOnPrimary,
          splashColor: AppColors.darkOnPrimary.withValues(alpha: 0.12),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.darkSurfaceContainerLow,
          selectedColor: AppColors.darkPrimaryContainer,
          disabledColor: AppColors.darkDisabled,
          side: BorderSide.none,
          labelStyle: const TextStyle(color: AppColors.darkOnSurface),
          secondaryLabelStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
