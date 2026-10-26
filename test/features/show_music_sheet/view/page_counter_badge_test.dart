import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/features/show_music_sheet/view/page_counter_badge.dart';

void main() {
  group('PageCounterBadge', () {
    testWidgets('shows current page and page count', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PageCounterBadge(currentPage: 2, pageCount: 3)));

      expect(find.text('2/3'), findsOneWidget);
    });

    testWidgets('shows nothing on a single-page sheet', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PageCounterBadge(currentPage: 1, pageCount: 1)));

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('shows nothing while the page count is unknown', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PageCounterBadge(currentPage: 1, pageCount: 0)));

      expect(find.byType(Text), findsNothing);
    });
  });
}
