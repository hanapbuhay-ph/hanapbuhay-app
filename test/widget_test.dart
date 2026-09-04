import 'package:flutter_test/flutter_test.dart';

import 'package:hanapbuhayapp/core/theme/app_colors.dart';
import 'package:hanapbuhayapp/core/theme/app_theme.dart';

void main() {
  testWidgets('dark theme defines stable material surface tokens', (WidgetTester tester) async {
    final theme = AppTheme.darkTheme;

    expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(theme.colorScheme.surface, AppColors.darkSurfaceContainer);
    expect(theme.colorScheme.surface, AppColors.darkSurfaceContainer);
    expect(theme.cardTheme.color, AppColors.darkSurfaceContainer);
    expect(theme.appBarTheme.backgroundColor, AppColors.darkSurfaceContainer);
    expect(theme.navigationBarTheme.backgroundColor, AppColors.darkSurfaceContainer);
    expect(theme.inputDecorationTheme.fillColor, AppColors.darkSurfaceContainer);
  });
}
