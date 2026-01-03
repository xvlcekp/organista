import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/widgets/empty_list_widget.dart';

void main() {
  group('EmptyListWidget', () {
    Widget createTestableWidget({
      required Widget child,
      Locale locale = const Locale('en'),
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('should display provided content correctly', (WidgetTester tester) async {
      const testIcon = Icons.music_off;
      const testTitle = 'No Music Found';
      const testSubtitle = 'Add some music sheets to get started';

      await tester.pumpWidget(
        createTestableWidget(
          child: const EmptyListWidget(
            icon: testIcon,
            title: testTitle,
            subtitle: testSubtitle,
          ),
        ),
      );

      // Verify the essential content is visible to the user
      expect(find.byIcon(testIcon), findsOneWidget);
      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testSubtitle), findsOneWidget);

      // Verify visual hierarchy (title and subtitle should be present)
      // Note: We trust the widget implementation to handle styling.
      // Verifying exact text style is brittle as AutoSizeText rendering can vary.
    });

    testWidgets('should include bouncing arrow indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const EmptyListWidget(
            icon: Icons.music_off,
            title: 'Title',
            subtitle: 'Subtitle',
          ),
        ),
      );

      // Verify the arrow icon acts as the indicator
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

      // Verify animation exists by checking position changes over time
      final arrowFinder = find.byIcon(Icons.arrow_downward);
      final initialPosition = tester.getCenter(arrowFinder);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));
      final newPosition = tester.getCenter(arrowFinder);

      // The arrow should have moved (bouncing effect)
      expect(initialPosition, isNot(equals(newPosition)));
    });

    testWidgets('should handle long text gracefully', (WidgetTester tester) async {
      const longTitle = 'This is a very long title that should be handled gracefully by the widget without overflowing';
      const longSubtitle =
          'This is an even longer subtitle that demonstrates how the widget handles very long text content that might wrap or resize automatically to fit the screen bounds';

      await tester.pumpWidget(
        createTestableWidget(
          child: const EmptyListWidget(
            icon: Icons.text_fields,
            title: longTitle,
            subtitle: longSubtitle,
          ),
        ),
      );

      // Content should still be present
      expect(find.text(longTitle), findsOneWidget);
      expect(find.text(longSubtitle), findsOneWidget);

      // And we shouldn't have overflow errors
      expect(tester.takeException(), isNull);
    });
  });
}
