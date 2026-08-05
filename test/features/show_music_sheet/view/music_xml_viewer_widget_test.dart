import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_controls_overlay.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_thumbnail_widget.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_viewer_widget.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:provider/provider.dart';

class MockCacheManager extends Mock implements CacheManager {}

class MockPlaylistBloc extends MockCubit<PlaylistState> implements PlaylistBloc {}

void main() {
  group('MusicXmlViewerWidget', () {
    late MockCacheManager mockCacheManager;
    late MockPlaylistBloc mockPlaylistBloc;
    late MusicSheetUrlSource urlSource;
    final bytesSource = MusicSheetBytesSource(
      bytes: Uint8List.fromList([1, 2, 3]),
      mediaType: MediaType.musicxml,
      fileName: 'song.musicxml',
    );

    setUp(() {
      mockCacheManager = MockCacheManager();
      mockPlaylistBloc = MockPlaylistBloc();

      final musicSheet = MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'id-1',
          MusicSheetKey.userId: 'user-1',
          MusicSheetKey.createdAt: Timestamp.now(),
          MusicSheetKey.fileUrl: 'https://example.com/song.musicxml',
          MusicSheetKey.fileName: 'song.musicxml',
          MusicSheetKey.originalFileStorageId: 'storage-id',
          MusicSheetKey.mediaType: 'musicxml',
          MusicSheetKey.sequenceId: 2,
          MusicSheetKey.transposition: 0,
        },
      );
      urlSource = MusicSheetUrlSource(musicSheet);
    });

    Widget buildWidget(MusicSheetSource source, MusicSheetViewMode mode) {
      return Provider<CacheManager>.value(
        value: mockCacheManager,
        child: BlocProvider<PlaylistBloc>.value(
          value: mockPlaylistBloc,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MusicXmlViewerWidget(source: source, mode: mode),
            ),
          ),
        ),
      );
    }

    testWidgets('shows placeholder message when source has no file data', (tester) async {
      await tester.pumpWidget(buildWidget(bytesSource, MusicSheetViewMode.full));

      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(find.text('No file data available'), findsOneWidget);
    });

    testWidgets('shows thumbnail widget in thumbnail mode for url source', (tester) async {
      await tester.pumpWidget(buildWidget(urlSource, MusicSheetViewMode.thumbnail));

      expect(find.byType(MusicXmlThumbnailWidget), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows loading indicator in full mode before webview is ready', (tester) async {
      await tester.pumpWidget(buildWidget(urlSource, MusicSheetViewMode.full));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(MusicXmlControlsOverlay), findsNothing);
    });

    testWidgets('shows loading indicator in preview mode before webview is ready', (tester) async {
      await tester.pumpWidget(buildWidget(urlSource, MusicSheetViewMode.preview));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
