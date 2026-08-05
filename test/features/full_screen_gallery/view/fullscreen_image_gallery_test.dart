import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/full_screen_gallery/view/fullscreen_image_gallery.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/playlists/playlist_key.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

class MockPlaylistBloc extends MockCubit<PlaylistState> implements PlaylistBloc {}

class MockCacheManager extends Mock implements CacheManager {}

void main() {
  group('FullScreenImageGallery', () {
    late MockPlaylistBloc mockPlaylistBloc;
    late MockCacheManager mockCacheManager;
    late Playlist playlist;

    setUp(() {
      mockPlaylistBloc = MockPlaylistBloc();
      mockCacheManager = MockCacheManager();

      Map<String, dynamic> sheetJson(String id) => {
        MusicSheetKey.musicSheetId: id,
        MusicSheetKey.userId: 'user-1',
        MusicSheetKey.createdAt: Timestamp.now(),
        MusicSheetKey.fileUrl: 'https://example.com/$id.png',
        MusicSheetKey.fileName: id,
        MusicSheetKey.originalFileStorageId: 'storage-$id',
        MusicSheetKey.mediaType: 'image',
        MusicSheetKey.sequenceId: 0,
      };

      playlist = Playlist(
        playlistId: 'playlist-1',
        json: {
          PlaylistKey.userId: 'user-1',
          PlaylistKey.createdAt: Timestamp.now(),
          PlaylistKey.name: 'Test playlist',
          PlaylistKey.musicSheets: [sheetJson('sheet-a'), sheetJson('sheet-b'), sheetJson('sheet-c')],
        },
      );

      when(() => mockPlaylistBloc.state).thenReturn(
        PlaylistLoadedState(isLoading: false, playlist: playlist),
      );
      when(() => mockPlaylistBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget buildWidget({int initialIndex = 0}) {
      return BlocProvider<PlaylistBloc>.value(
        value: mockPlaylistBloc,
        child: Provider<CacheManager>.value(
          value: mockCacheManager,
          child: MaterialApp(
            home: FullScreenImageGallery(initialIndex: initialIndex),
          ),
        ),
      );
    }

    testWidgets('renders the music sheet at the initial index wrapped in a MusicSheetSource', (tester) async {
      await tester.pumpWidget(buildWidget(initialIndex: 1));
      await tester.pump();

      final musicSheetViews = tester.widgetList<MusicSheetView>(find.byType(MusicSheetView));
      expect(musicSheetViews, isNotEmpty);
      for (final view in musicSheetViews) {
        expect(view.source, isA<MusicSheetUrlSource>());
        expect(view.mode, MusicSheetViewMode.full);
      }
      expect(find.byKey(const ValueKey('sheet-b')), findsOneWidget);
    });

    testWidgets('enables full screen system UI mode and restores it on dispose', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      // Disposing should not throw when restoring the system UI mode.
      expect(tester.takeException(), isNull);
    });

    testWidgets('pressing the right arrow key advances to the next page', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final galleryBefore = tester.widget<PhotoViewGallery>(find.byType(PhotoViewGallery));
      expect(galleryBefore.pageController!.page, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      final galleryAfter = tester.widget<PhotoViewGallery>(find.byType(PhotoViewGallery));
      expect(galleryAfter.pageController!.page, 1);
    });

    testWidgets('pressing the left arrow key does nothing on the first page', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      final gallery = tester.widget<PhotoViewGallery>(find.byType(PhotoViewGallery));
      expect(gallery.pageController!.page, 0);
    });
  });
}
