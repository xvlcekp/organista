import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/features/full_screen_gallery/view/gallery_shortcuts.dart';

void main() {
  group('GalleryShortcuts', () {
    bool nextCalled = false;
    bool previousCalled = false;

    Widget createTestableWidget() {
      return MaterialApp(
        home: GalleryShortcuts(
          onNext: () => nextCalled = true,
          onPrevious: () => previousCalled = true,
          child: const Scaffold(body: Text('Test Child')),
        ),
      );
    }

    setUp(() {
      nextCalled = false;
      previousCalled = false;
    });

    testWidgets('should call onNext when arrowRight is pressed', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(nextCalled, isTrue);
    });

    testWidgets('should call onNext when arrowDown is pressed', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(nextCalled, isTrue);
    });

    testWidgets('should call onPrevious when arrowLeft is pressed', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(previousCalled, isTrue);
    });

    testWidgets('should call onPrevious when arrowUp is pressed', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(previousCalled, isTrue);
    });
  });
}
