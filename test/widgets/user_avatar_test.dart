import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/widgets/user_avatar.dart';

void main() {
  testWidgets(
    'shows white initials on the theme primary color without a photo',
    (tester) async {
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.green);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: colorScheme),
          home: const Scaffold(
            body: UserAvatar(name: 'Maria Santos', radius: 32),
          ),
        ),
      );

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      final initials = tester.widget<Text>(find.text('MS'));

      expect(avatar.backgroundColor, colorScheme.primary);
      expect(initials.style?.color, Colors.white);
    },
  );

  testWidgets('invokes its tap callback when tapped', (tester) async {
    var wasTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserAvatar(
            name: 'Maria Santos',
            radius: 32,
            onTap: () => wasTapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(UserAvatar));

    expect(wasTapped, isTrue);
  });
}
