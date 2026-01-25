import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/features/show_music_sheet/view/back_button_widget.dart';
import 'package:organista/l10n/app_localizations.dart';

void main() {
  group('BackButtonWidget', () {
    Widget createTestableWidget({
      required Widget child,
      Locale locale = const Locale('en'),
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Scaffold(
          body: Stack(
            children: [child],
          ),
        ),
      );
    }

    testWidgets('should render back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const BackButtonWidget(),
        ),
      );

      // Verify the back button is present
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(Positioned), findsOneWidget);
    });

    testWidgets('should have correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const BackButtonWidget(),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(BackButtonWidget),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, Colors.black.withValues(alpha: BackButtonWidget.opacity));
    });

    testWidgets('should position correctly with safe area', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const BackButtonWidget(),
        ),
      );

      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(BackButtonWidget),
          matching: find.byType(Positioned),
        ),
      );

      // The top position should account for safe area padding
      expect(positioned.top, isNotNull);
      expect(positioned.left, BackButtonWidget.padding);
    });

    testWidgets('should use localized tooltip text', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const BackButtonWidget(),
          locale: const Locale('en'),
        ),
      );

      // The IconButton should be present and have a tooltip
      expect(find.byType(IconButton), findsOneWidget);
      // Verify the tooltip contains the localized "Back" text
      expect(find.byTooltip('Back'), findsOneWidget);
    });

    testWidgets('should have onPressed callback', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const BackButtonWidget(),
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );

      // Verify the button has a press callback (not null)
      expect(iconButton.onPressed, isNotNull);
    });
  });
}
