import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/features/show_music_sheet/view/dismissable_title.dart';

void main() {
  group('DismissableTitle', () {
    Widget buildWidget({required String title, required VoidCallback onDismiss}) {
      return MaterialApp(
        home: Scaffold(
          body: DismissableTitle(title: title, onDismiss: onDismiss),
        ),
      );
    }

    testWidgets('renders the title text', (tester) async {
      await tester.pumpWidget(buildWidget(title: 'Amazing Grace', onDismiss: () {}));

      expect(find.text('Amazing Grace'), findsOneWidget);
    });

    testWidgets('calls onDismiss when tapped', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(buildWidget(title: 'Test', onDismiss: () => dismissed = true));

      await tester.tap(find.byType(DismissableTitle));
      expect(dismissed, isTrue);
    });

    testWidgets('text uses ellipsis overflow', (tester) async {
      await tester.pumpWidget(buildWidget(title: 'A very long title that should overflow', onDismiss: () {}));

      final textWidget = tester.widget<Text>(find.text('A very long title that should overflow'));
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('container has rounded decoration', (tester) async {
      await tester.pumpWidget(buildWidget(title: 'Test', onDismiss: () {}));

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(DismissableTitle), matching: find.byType(Container)),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
    });
  });
}
