import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/playlists/playlist_key.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/services/export_playlist/export_playlist_service.dart';

import 'playlist_bloc_test.mocks.dart';

@GenerateMocks([FirebaseFirestoreRepository, ExportPlaylistService])
void main() {
  group('PlaylistBloc', () {
    late PlaylistBloc bloc;
    late MockFirebaseFirestoreRepository mockFirebaseFirestoreRepository;
    late MockExportPlaylistService mockExportService;
    late AuthUser testUser;
    late Playlist testPlaylist;
    late MusicSheet testMusicSheet;
    late Timestamp testTimestamp;

    setUp(() {
      mockFirebaseFirestoreRepository = MockFirebaseFirestoreRepository();
      mockExportService = MockExportPlaylistService();

      testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30));
      testUser = const AuthUser(
        id: 'user1',
        email: 'test@example.com',
        isEmailVerified: true,
      );

      testMusicSheet = MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: 'sheet1',
          MusicSheetKey.userId: 'user1',
          MusicSheetKey.createdAt: testTimestamp,
          MusicSheetKey.fileUrl: 'https://example.com/sheet.pdf',
          MusicSheetKey.fileName: 'Test Sheet',
          MusicSheetKey.originalFileStorageId: 'storage1',
          MusicSheetKey.mediaType: 'pdf',
          MusicSheetKey.sequenceId: 1,
        },
      );

      testPlaylist = Playlist(
        playlistId: 'playlist1_test_${DateTime.now().millisecondsSinceEpoch}',
        json: {
          PlaylistKey.userId: 'user1',
          PlaylistKey.createdAt: testTimestamp,
          PlaylistKey.name: 'Test Playlist',
          PlaylistKey.musicSheets: [testMusicSheet.toJson()],
        },
      );

      bloc = PlaylistBloc(
        firebaseFirestoreRepository: mockFirebaseFirestoreRepository,
        exportService: mockExportService,
      );
    });

    tearDown(() {
      bloc.close();
    });

    group('InitPlaylistEvent', () {
      blocTest<PlaylistBloc, PlaylistState>(
        'emits [PlaylistLoadedState] when init succeeds',
        setUp: () {
          when(
            mockFirebaseFirestoreRepository.getPlaylistStream(testPlaylist.playlistId),
          ).thenAnswer((_) => Stream.value(testPlaylist));
        },
        build: () => bloc,
        act: (bloc) => bloc.add(
          InitPlaylistEvent(
            user: testUser,
            playlist: testPlaylist,
          ),
        ),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        ],
      );
    });

    group('DeleteMusicSheetInPlaylistEvent', () {
      blocTest<PlaylistBloc, PlaylistState>(
        'emits [PlaylistLoadedState(isLoading: true), PlaylistLoadedState(isLoading: false)] when delete succeeds',
        setUp: () {
          when(
            mockFirebaseFirestoreRepository.deleteMusicSheetInPlaylist(
              musicSheet: testMusicSheet,
              playlist: testPlaylist,
            ),
          ).thenAnswer((_) async => true);
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(
          DeleteMusicSheetInPlaylistEvent(
            musicSheet: testMusicSheet,
            playlist: testPlaylist,
          ),
        ),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        ],
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'emits [PlaylistLoadedState(isLoading: true), PlaylistErrorState] when delete fails',
        setUp: () {
          when(
            mockFirebaseFirestoreRepository.deleteMusicSheetInPlaylist(
              musicSheet: testMusicSheet,
              playlist: testPlaylist,
            ),
          ).thenThrow(Exception('Delete failed'));
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(
          DeleteMusicSheetInPlaylistEvent(
            musicSheet: testMusicSheet,
            playlist: testPlaylist,
          ),
        ),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          isA<PlaylistErrorState>(),
        ],
      );
    });

    group('ReorderMusicSheetEvent', () {
      blocTest<PlaylistBloc, PlaylistState>(
        'emits [PlaylistLoadedState(isLoading: true), PlaylistLoadedState(isLoading: false)] when reorder succeeds',
        setUp: () {
          when(mockFirebaseFirestoreRepository.musicSheetReorder(playlist: testPlaylist)).thenAnswer((_) async => true);
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(ReorderMusicSheetEvent(playlist: testPlaylist)),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        ],
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'emits [PlaylistLoadedState(isLoading: true), PlaylistErrorState] when reorder fails',
        setUp: () {
          when(
            mockFirebaseFirestoreRepository.musicSheetReorder(playlist: testPlaylist),
          ).thenAnswer((_) async => Future.error(Exception('Reorder failed')));
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(ReorderMusicSheetEvent(playlist: testPlaylist)),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          isA<PlaylistErrorState>(),
        ],
      );
    });

    group('AddMusicSheetsToPlaylistEvent', () {
      late List<MusicSheet> newMusicSheets;

      setUp(() {
        newMusicSheets = [
          MusicSheet(
            json: {
              MusicSheetKey.musicSheetId: 'sheet2',
              MusicSheetKey.userId: 'user1',
              MusicSheetKey.createdAt: testTimestamp,
              MusicSheetKey.fileUrl: 'https://example.com/sheet2.pdf',
              MusicSheetKey.fileName: 'New Sheet',
              MusicSheetKey.originalFileStorageId: 'storage2',
              MusicSheetKey.mediaType: 'pdf',
              MusicSheetKey.sequenceId: 2,
            },
          ),
        ];
      });

      blocTest<PlaylistBloc, PlaylistState>(
        'emits [PlaylistLoadedState(isLoading: true), PlaylistLoadedState(isLoading: false)] when add succeeds',
        setUp: () {
          when(
            mockFirebaseFirestoreRepository.addMusicSheetsToPlaylist(
              playlist: testPlaylist,
              musicSheets: newMusicSheets,
            ),
          ).thenAnswer((_) async => true);
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(
          AddMusicSheetsToPlaylistEvent(
            musicSheets: newMusicSheets,
            playlist: testPlaylist,
          ),
        ),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
        ],
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'emits [PlaylistLoadedState(isLoading: true), PlaylistErrorState] when add fails with capacity exceeded',
        setUp: () {
          when(
            mockFirebaseFirestoreRepository.addMusicSheetsToPlaylist(
              playlist: testPlaylist,
              musicSheets: newMusicSheets,
            ),
          ).thenThrow(
            PlaylistCapacityExceededError(
              playlist: testPlaylist,
              attemptedToAdd: 1,
              maxCapacity: 10,
            ),
          );
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(
          AddMusicSheetsToPlaylistEvent(
            musicSheets: newMusicSheets,
            playlist: testPlaylist,
          ),
        ),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          isA<PlaylistErrorState>(),
        ],
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'emits [PlaylistLoadedState(isLoading: true), PlaylistErrorState] with duplicates',
        setUp: () {
          when(
            mockFirebaseFirestoreRepository.addMusicSheetsToPlaylist(
              playlist: testPlaylist,
              musicSheets: [testMusicSheet], // Same sheet already in playlist
            ),
          ).thenAnswer((_) async => true);
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(
          AddMusicSheetsToPlaylistEvent(
            musicSheets: [testMusicSheet],
            playlist: testPlaylist,
          ),
        ),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          isA<PlaylistErrorState>(),
        ],
      );
    });

    group('ExportPlaylistEvent', () {
      blocTest<PlaylistBloc, PlaylistState>(
        'emits [PlaylistLoadedState(isLoading: true), PlaylistReadyToExportState] when export succeeds',
        setUp: () {
          when(
            mockExportService.exportPlaylistToPdf(playlist: testPlaylist),
          ).thenAnswer((_) async => '/temp/exported.pdf');
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(ExportPlaylistEvent(playlist: testPlaylist)),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          PlaylistReadyToExportState(
            isLoading: false,
            playlist: testPlaylist,
            tempPath: '/temp/exported.pdf',
            playlistName: testPlaylist.name,
          ),
        ],
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'emits [PlaylistLoadedState(isLoading: true), PlaylistErrorState] when export fails',
        setUp: () {
          when(mockExportService.exportPlaylistToPdf(playlist: testPlaylist)).thenAnswer((_) async => null);
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(ExportPlaylistEvent(playlist: testPlaylist)),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          isA<PlaylistErrorState>(),
        ],
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'emits [PlaylistLoadedState(isLoading: true), PlaylistErrorState] when playlist is empty',
        build: () => bloc,
        seed: () => PlaylistLoadedState(
          isLoading: false,
          playlist: Playlist(
            playlistId: 'playlist1',
            json: {
              PlaylistKey.userId: 'user1',
              PlaylistKey.createdAt: testTimestamp,
              PlaylistKey.name: 'Test Playlist',
              PlaylistKey.musicSheets: const [],
            },
          ),
        ),
        act: (bloc) => bloc.add(
          ExportPlaylistEvent(
            playlist: Playlist(
              playlistId: 'playlist1',
              json: {
                PlaylistKey.userId: 'user1',
                PlaylistKey.createdAt: testTimestamp,
                PlaylistKey.name: 'Test Playlist',
                PlaylistKey.musicSheets: const [],
              },
            ),
          ),
        ),
        expect: () => [
          isA<PlaylistErrorState>(),
        ],
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'emits [PlaylistLoadedState(isLoading: true), PlaylistErrorState] when export throws exception',
        setUp: () {
          when(
            mockExportService.exportPlaylistToPdf(playlist: testPlaylist),
          ).thenAnswer((_) async => Future.error(Exception('Export failed')));
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(ExportPlaylistEvent(playlist: testPlaylist)),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          isA<PlaylistErrorState>(),
        ],
      );
    });

    // Tests for SaveExportedPlaylistEvent are omitted because FilePicker
    // requires platform channels that are not available in unit tests.
  });
}
