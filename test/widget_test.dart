import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:hanapbuhayapp/core/theme/app_colors.dart';
import 'package:hanapbuhayapp/core/theme/app_theme.dart';

void main() {
  test('all onboarding illustrations are bundled as assets', () async {
    const assets = [
      'assets/images/onboarding/onboarding_01_welcome.png',
      'assets/images/onboarding/onboarding_02_find_worker.png',
      'assets/images/onboarding/onboarding_03_offer_skills.png',
      'assets/images/onboarding/onboarding_04_verified.png',
    ];

    for (final asset in assets) {
      expect(await rootBundle.load(asset), isNotNull);
    }
  });

  testWidgets('dark theme defines stable material surface tokens', (
    WidgetTester tester,
  ) async {
    final theme = AppTheme.darkTheme;

    expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(theme.colorScheme.surface, AppColors.darkSurfaceContainer);
    expect(theme.colorScheme.surface, AppColors.darkSurfaceContainer);
    expect(theme.cardTheme.color, AppColors.darkSurfaceContainer);
    expect(theme.appBarTheme.backgroundColor, AppColors.darkSurfaceContainer);
    expect(theme.appBarTheme.foregroundColor, AppColors.darkPrimary);
    expect(
      theme.navigationBarTheme.backgroundColor,
      AppColors.darkSurfaceContainer,
    );
    expect(
      theme.inputDecorationTheme.fillColor,
      AppColors.darkSurfaceContainer,
    );
  });

  test(
    'dark theme uses the app green palette with contrasting dark-mode roles',
    () {
      final colorScheme = AppTheme.darkTheme.colorScheme;

      expect(colorScheme.primary, AppColors.primaryContainer);
      expect(colorScheme.onPrimary, AppColors.onPrimaryContainer);
      expect(colorScheme.primaryContainer, AppColors.primary);
      expect(colorScheme.onPrimaryContainer, AppColors.onPrimary);
      expect(colorScheme.secondary, AppColors.secondaryContainer);
      expect(colorScheme.secondaryContainer, AppColors.secondary);
    },
  );
}
