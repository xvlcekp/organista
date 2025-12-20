import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_playlist/view/playlist_view.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/playlists/playlist_key.dart';
import 'package:provider/provider.dart';

import '../bloc/playlist_bloc_test.mocks.dart';

class PlaylistViewTest extends PlaylistBloc {
  PlaylistViewTest({
    required super.firebaseFirestoreRepository,
    required super.exportService,
  });

  void _setStateForTest(PlaylistState state) => emit(state);
}

void main() {
  group('PlaylistView', () {
    late PlaylistViewTest bloc;
    late MockFirebaseFirestoreRepository mockFirebaseFirestoreRepository;
    late MockExportPlaylistService mockExportService;
    late Playlist testPlaylist;
    late Timestamp testTimestamp;

    setUp(() {
      mockFirebaseFirestoreRepository = MockFirebaseFirestoreRepository();
      mockExportService = MockExportPlaylistService();
      testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30));

      testPlaylist = Playlist(
        playlistId: 'playlist1',
        json: {
          PlaylistKey.userId: 'user1',
          PlaylistKey.createdAt: testTimestamp,
          PlaylistKey.name: 'Test Playlist',
          PlaylistKey.musicSheets: [
            {
              MusicSheetKey.musicSheetId: 'sheet1',
              MusicSheetKey.userId: 'user1',
              MusicSheetKey.createdAt: testTimestamp,
              MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
              MusicSheetKey.fileName: 'Test Sheet',
              MusicSheetKey.originalFileStorageId: 'storage1',
              MusicSheetKey.mediaType: 'pdf',
              MusicSheetKey.sequenceId: 1,
            },
          ],
        },
      );

      bloc = PlaylistViewTest(
        firebaseFirestoreRepository: mockFirebaseFirestoreRepository,
        exportService: mockExportService,
      );
    });

    tearDown(() {
      bloc.close();
    });

    Widget createTestWidget() {
      return BlocProvider<PlaylistBloc>.value(
        value: bloc,
        child: Provider<CacheManager>.value(
          value: DefaultCacheManager(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HookBuilder(
              builder: (context) => const PlaylistView(),
            ),
          ),
        ),
      );
    }

    testWidgets('displays playlist name in app bar', (tester) async {
      bloc._setStateForTest(
        PlaylistLoadedState(
          isLoading: false,
          playlist: testPlaylist,
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Test Playlist'), findsOneWidget);
    });

    testWidgets('shows edit and export buttons in app bar', (tester) async {
      bloc._setStateForTest(
        PlaylistLoadedState(
          isLoading: false,
          playlist: testPlaylist,
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.edit), findsOneWidget);

      // Open the popup menu to find the export icon
      final menuButton = find.byIcon(Icons.more_vert);
      expect(menuButton, findsOneWidget);

      await tester.tap(menuButton);
      await tester.pump();

      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('shows music sheet list when playlist has sheets', (tester) async {
      bloc._setStateForTest(
        PlaylistLoadedState(
          isLoading: false,
          playlist: testPlaylist,
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Test Sheet'), findsOneWidget);
    });

    testWidgets('shows empty list widget when playlist has no sheets', (tester) async {
      bloc._setStateForTest(
        PlaylistLoadedState(
          isLoading: false,
          playlist: Playlist.empty(),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.music_off), findsOneWidget);
    });
    testWidgets(
      'shows floating action button and hide when in edit mode',
      (tester) async {
        bloc._setStateForTest(
          PlaylistLoadedState(
            isLoading: false,
            playlist: Playlist.empty(),
          ),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Tap edit button to enter edit mode
        expect(find.byType(FloatingActionButton), findsOneWidget);
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );

    testWidgets(
      'shows check icon when in edit mode',
      (tester) async {
        bloc._setStateForTest(
          PlaylistLoadedState(
            isLoading: false,
            playlist: Playlist.empty(),
          ),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Tap edit button to enter edit mode
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pump();

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsNothing);
      },
    );
  });
}
