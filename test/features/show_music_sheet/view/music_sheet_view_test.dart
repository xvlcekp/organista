import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/show_music_sheet/view/back_button_widget.dart';
import 'package:organista/features/show_music_sheet/view/dismissable_title.dart';
import 'package:organista/features/show_music_sheet/view/image_viewer_widget.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_viewer_widget.dart';
import 'package:organista/features/show_music_sheet/view/pdf_viewer_widget.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:provider/provider.dart';

class MockCacheManager extends Mock implements CacheManager {}

void main() {
  group('MusicSheetView', () {
    late MockCacheManager mockCacheManager;

    setUp(() {
      mockCacheManager = MockCacheManager();
    });

    MusicSheetSource buildSource(String mediaType) {
      final musicSheet = MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'id-1',
          MusicSheetKey.userId: 'user-1',
          MusicSheetKey.createdAt: Timestamp.now(),
          MusicSheetKey.fileUrl: 'https://example.com/sheet',
          MusicSheetKey.fileName: 'my sheet',
          MusicSheetKey.originalFileStorageId: 'storage-id',
          MusicSheetKey.mediaType: mediaType,
          MusicSheetKey.sequenceId: 0,
        },
      );
      return MusicSheetUrlSource(musicSheet);
    }

    Widget buildWidget(MusicSheetSource source, MusicSheetViewMode mode) {
      return Provider<CacheManager>.value(
        value: mockCacheManager,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MusicSheetView(source: source, mode: mode),
          ),
        ),
      );
    }

    testWidgets('renders ImageViewerWidget for image media type', (tester) async {
      await tester.pumpWidget(buildWidget(buildSource('image'), MusicSheetViewMode.thumbnail));

      expect(find.byType(ImageViewerWidget), findsOneWidget);
      expect(find.byType(PdfViewerWidget), findsNothing);
      expect(find.byType(MusicXmlViewerWidget), findsNothing);
    });

    testWidgets('renders PdfViewerWidget for pdf media type', (tester) async {
      await tester.pumpWidget(buildWidget(buildSource('pdf'), MusicSheetViewMode.thumbnail));

      expect(find.byType(PdfViewerWidget), findsOneWidget);
      expect(find.byType(ImageViewerWidget), findsNothing);
    });

    testWidgets('renders MusicXmlViewerWidget for musicxml media type', (tester) async {
      await tester.pumpWidget(buildWidget(buildSource('musicxml'), MusicSheetViewMode.thumbnail));

      expect(find.byType(MusicXmlViewerWidget), findsOneWidget);
      expect(find.byType(ImageViewerWidget), findsNothing);
    });

    testWidgets('shows back button and title overlay in full mode', (tester) async {
      await tester.pumpWidget(buildWidget(buildSource('image'), MusicSheetViewMode.full));

      expect(find.byType(BackButtonWidget), findsOneWidget);
      expect(find.byType(DismissableTitle), findsOneWidget);
      expect(find.text('my sheet'), findsOneWidget);
    });

    testWidgets('hides back button and title overlay outside full mode', (tester) async {
      await tester.pumpWidget(buildWidget(buildSource('image'), MusicSheetViewMode.preview));

      expect(find.byType(BackButtonWidget), findsNothing);
      expect(find.byType(DismissableTitle), findsNothing);
    });

    testWidgets('dismissing the title hides it', (tester) async {
      await tester.pumpWidget(buildWidget(buildSource('image'), MusicSheetViewMode.full));
      expect(find.byType(DismissableTitle), findsOneWidget);

      await tester.tap(find.byType(DismissableTitle));
      await tester.pump();

      expect(find.byType(DismissableTitle), findsNothing);
      // The back button and underlying viewer remain unaffected by dismissing the title.
      expect(find.byType(BackButtonWidget), findsOneWidget);
    });

    testWidgets('renders a bytes source without needing a network round trip', (tester) async {
      final source = MusicSheetBytesSource(
        bytes: Uint8List.fromList([1, 2, 3]),
        mediaType: MediaType.image,
        fileName: 'from-disk.png',
      );

      await tester.pumpWidget(buildWidget(source, MusicSheetViewMode.full));

      expect(find.byType(ImageViewerWidget), findsOneWidget);
      expect(find.text('from-disk.png'), findsOneWidget);
    });
  });
}
