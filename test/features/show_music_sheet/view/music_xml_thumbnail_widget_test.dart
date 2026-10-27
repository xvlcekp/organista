import 'dart:async';
import 'dart:io' show SocketException;

import 'package:file/file.dart';
import 'package:file/memory.dart';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_thumbnail_widget.dart';
import 'package:organista/features/show_music_sheet/view/sheet_load_error.dart';
import 'package:provider/provider.dart';

class MockCacheManager extends Mock implements CacheManager {}

void main() {
  group('MusicXmlThumbnailWidget', () {
    late MockCacheManager cacheManager;

    setUp(() {
      cacheManager = MockCacheManager();
      // Still downloading by default; the number is shown meanwhile.
      when(() => cacheManager.getSingleFile(any())).thenAnswer((_) => Completer<File>().future);
    });

    Widget buildWidget({int? sequenceId}) {
      return Provider<CacheManager>.value(
        value: cacheManager,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: MusicXmlThumbnailWidget(fileUrl: 'https://example.com/song.musicxml', sequenceId: sequenceId),
            ),
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

    testWidgets('fetches the file through the cache like the other thumbnails', (tester) async {
      await tester.pumpWidget(buildWidget(sequenceId: 3));

      verify(() => cacheManager.getSingleFile('https://example.com/song.musicxml')).called(1);
    });

    testWidgets('keeps the number once the file is on the device', (tester) async {
      when(() => cacheManager.getSingleFile(any())).thenAnswer((_) async => MemoryFileSystem().file('song.musicxml'));

      await tester.pumpWidget(buildWidget(sequenceId: 3));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
      expect(find.byType(SheetLoadError), findsNothing);
    });

    testWidgets('shows the shared load error when the file cannot be fetched', (tester) async {
      when(() => cacheManager.getSingleFile(any())).thenAnswer((_) async => throw const SocketException('offline'));

      await tester.pumpWidget(buildWidget(sequenceId: 3));
      await tester.pump();

      expect(find.byType(SheetLoadError), findsOneWidget);
      expect(find.text('3'), findsNothing);
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
