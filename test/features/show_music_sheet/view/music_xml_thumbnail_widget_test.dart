import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_thumbnail_widget.dart';

void main() {
  group('MusicXmlThumbnailWidget', () {
    Widget buildWidget({int? sequenceId}) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: MusicXmlThumbnailWidget(sequenceId: sequenceId),
          ),
        ),
      );
    }

    testWidgets('shows sequence ID when sequenceId > 0', (tester) async {
      await tester.pumpWidget(buildWidget(sequenceId: 3));

      expect(find.text('3'), findsOneWidget);
      expect(find.text('XML'), findsNothing);
    });

    testWidgets('shows XML when sequenceId is null', (tester) async {
      await tester.pumpWidget(buildWidget(sequenceId: null));

      expect(find.text('XML'), findsOneWidget);
    });

    testWidgets('shows XML when sequenceId is 0', (tester) async {
      await tester.pumpWidget(buildWidget(sequenceId: 0));

      expect(find.text('XML'), findsOneWidget);
    });

    testWidgets('has white background with grey border', (tester) async {
      await tester.pumpWidget(buildWidget(sequenceId: 1));

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(MusicXmlThumbnailWidget), matching: find.byType(Container)),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.white);
      expect(decoration.border, isNotNull);
    });

    testWidgets('text is bold', (tester) async {
      await tester.pumpWidget(buildWidget(sequenceId: 5));

      final text = tester.widget<Text>(find.text('5'));
      expect(text.style?.fontWeight, FontWeight.bold);
    });
  });
}
