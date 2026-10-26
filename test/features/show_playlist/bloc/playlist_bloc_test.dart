import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/config/app_constants.dart';
import 'package:file/memory.dart';
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
import 'package:organista/services/connectivity/connectivity_service.dart';
import 'package:organista/services/export_playlist/export_playlist_service.dart';

import 'playlist_bloc_test.mocks.dart';

@GenerateMocks([FirebaseFirestoreRepository, ExportPlaylistService, ConnectivityService, CacheManager])
void main() {
  group('PlaylistBloc', () {
    late PlaylistBloc bloc;
    late MockFirebaseFirestoreRepository mockFirebaseFirestoreRepository;
    late MockExportPlaylistService mockExportService;
    late MockConnectivityService mockConnectivityService;
    late MockCacheManager mockCacheManager;
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

      mockConnectivityService = MockConnectivityService();
      when(mockConnectivityService.isOnline).thenReturn(true);
      mockCacheManager = MockCacheManager();
      bloc = PlaylistBloc(
        firebaseFirestoreRepository: mockFirebaseFirestoreRepository,
        exportService: mockExportService,
        connectivityService: mockConnectivityService,
        cacheManager: mockCacheManager,
      );
    });

    group('AddMusicSheetsToPlaylistEvent offline', () {
      MusicSheet newSheet({String id = 'sheet-offline'}) => MusicSheet(
        json: {
          MusicSheetKey.musicSheetId: id,
          MusicSheetKey.userId: 'user1',
          MusicSheetKey.createdAt: testTimestamp,
          MusicSheetKey.fileUrl: 'https://example.com/offline.pdf',
          MusicSheetKey.fileName: 'offline.pdf',
          MusicSheetKey.originalFileStorageId: 'storage-offline',
          MusicSheetKey.mediaType: 'pdf',
          MusicSheetKey.sequenceId: 2,
        },
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'rejects a sheet that is not on the device right away instead of waiting for the Firestore write, on every '
        'attempt',
        setUp: () {
          when(mockConnectivityService.isOnline).thenReturn(false);
          when(mockCacheManager.getFileFromCache(any)).thenAnswer((_) async => null);
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc
          ..add(AddMusicSheetsToPlaylistEvent(musicSheets: [newSheet()], playlist: testPlaylist))
          ..add(AddMusicSheetsToPlaylistEvent(musicSheets: [newSheet()], playlist: testPlaylist)),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          PlaylistErrorState(error: const PlaylistErrorNoInternet(), playlist: testPlaylist),
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          PlaylistErrorState(error: const PlaylistErrorNoInternet(), playlist: testPlaylist),
        ],
        verify: (_) => verifyNever(
          mockFirebaseFirestoreRepository.addMusicSheetsToPlaylist(
            playlist: anyNamed('playlist'),
            musicSheets: anyNamed('musicSheets'),
          ),
        ),
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'adds a cached sheet without waiting for the server; the playlist stream delivers the local write',
        setUp: () {
          when(mockConnectivityService.isOnline).thenReturn(false);
          when(mockCacheManager.getFileFromCache(any)).thenAnswer(
            (_) async => FileInfo(MemoryFileSystem().file('cached.pdf'), FileSource.Cache, DateTime(2027), 'url'),
          );
          // Offline, Firestore completes the write only once it is back online.
          when(
            mockFirebaseFirestoreRepository.addMusicSheetsToPlaylist(
              playlist: anyNamed('playlist'),
              musicSheets: anyNamed('musicSheets'),
            ),
          ).thenAnswer((_) => Completer<bool>().future);
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(AddMusicSheetsToPlaylistEvent(musicSheets: [newSheet()], playlist: testPlaylist)),
        expect: () => [PlaylistLoadedState(isLoading: true, playlist: testPlaylist)],
        verify: (_) => verify(
          mockFirebaseFirestoreRepository.addMusicSheetsToPlaylist(playlist: testPlaylist, musicSheets: [newSheet()]),
        ).called(1),
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'still enforces the playlist capacity offline',
        setUp: () {
          when(mockConnectivityService.isOnline).thenReturn(false);
          when(mockCacheManager.getFileFromCache(any)).thenAnswer(
            (_) async => FileInfo(MemoryFileSystem().file('cached.pdf'), FileSource.Cache, DateTime(2027), 'url'),
          );
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(
          AddMusicSheetsToPlaylistEvent(
            musicSheets: List.generate(AppConstants.maxPlaylistCapacity, (i) => newSheet(id: 'sheet-$i')),
            playlist: testPlaylist,
          ),
        ),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          isA<PlaylistErrorState>().having((s) => s.error, 'error', isA<PlaylistCapacityExceededError>()),
        ],
        verify: (_) => verifyNever(
          mockFirebaseFirestoreRepository.addMusicSheetsToPlaylist(
            playlist: anyNamed('playlist'),
            musicSheets: anyNamed('musicSheets'),
          ),
        ),
      );
    });

    group('ExportPlaylistEvent offline', () {
      blocTest<PlaylistBloc, PlaylistState>(
        'explains a failed export by the missing network when the device is offline',
        setUp: () {
          when(mockConnectivityService.isOnline).thenReturn(false);
          when(mockExportService.exportPlaylistToPdf(playlist: anyNamed('playlist'))).thenAnswer((_) async => null);
        },
        build: () => bloc,
        act: (bloc) => bloc.add(ExportPlaylistEvent(playlist: testPlaylist)),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          PlaylistErrorState(error: const ExportPlaylistOfflineError(), playlist: testPlaylist),
        ],
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'keeps the generic export error while online',
        setUp: () {
          when(mockExportService.exportPlaylistToPdf(playlist: anyNamed('playlist'))).thenAnswer((_) async => null);
        },
        build: () => bloc,
        act: (bloc) => bloc.add(ExportPlaylistEvent(playlist: testPlaylist)),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          PlaylistErrorState(error: const ExportPlaylistError(), playlist: testPlaylist),
        ],
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
        'emits [PlaylistLoadedState(isLoading: true), PlaylistErrorState] when the repository reports the delete was not written',
        setUp: () {
          when(
            mockFirebaseFirestoreRepository.deleteMusicSheetInPlaylist(
              musicSheet: testMusicSheet,
              playlist: testPlaylist,
            ),
          ).thenAnswer((_) async => false);
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
          PlaylistErrorState(error: const PlaylistErrorUnknown(), playlist: testPlaylist),
        ],
      );

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
        'emits [PlaylistLoadedState(isLoading: true), PlaylistErrorState] when the repository reports the reorder was not written',
        setUp: () {
          when(
            mockFirebaseFirestoreRepository.musicSheetReorder(playlist: testPlaylist),
          ).thenAnswer((_) async => false);
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(ReorderMusicSheetEvent(playlist: testPlaylist)),
        expect: () => [
          PlaylistLoadedState(isLoading: true, playlist: testPlaylist),
          PlaylistErrorState(error: const PlaylistErrorUnknown(), playlist: testPlaylist),
        ],
      );

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
        'emits [PlaylistLoadedState(isLoading: true), PlaylistErrorState] when the repository reports the add was not written',
        setUp: () {
          when(
            mockFirebaseFirestoreRepository.addMusicSheetsToPlaylist(
              playlist: testPlaylist,
              musicSheets: newMusicSheets,
            ),
          ).thenAnswer((_) async => false);
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
          PlaylistErrorState(error: const PlaylistErrorUnknown(), playlist: testPlaylist),
        ],
      );

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

    group('UpdateMusicSheetTranspositionEvent', () {
      blocTest<PlaylistBloc, PlaylistState>(
        'calls repository to update transposition and emits no new state',
        setUp: () {
          when(
            mockFirebaseFirestoreRepository.updateMusicSheetTransposition(
              musicSheet: testMusicSheet,
              transposition: 3,
              playlist: testPlaylist,
            ),
          ).thenAnswer((_) async => true);
        },
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(
          UpdateMusicSheetTranspositionEvent(
            musicSheet: testMusicSheet,
            transposition: 3,
          ),
        ),
        verify: (_) {
          verify(
            mockFirebaseFirestoreRepository.updateMusicSheetTransposition(
              musicSheet: testMusicSheet,
              transposition: 3,
              playlist: testPlaylist,
            ),
          ).called(1);
        },
        expect: () => [],
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'does not call repository when no playlist has been loaded (initial state)',
        build: () => bloc,
        act: (bloc) => bloc.add(
          UpdateMusicSheetTranspositionEvent(
            musicSheet: testMusicSheet,
            transposition: 3,
          ),
        ),
        verify: (_) {
          verifyNever(
            mockFirebaseFirestoreRepository.updateMusicSheetTransposition(
              musicSheet: anyNamed('musicSheet'),
              transposition: anyNamed('transposition'),
              playlist: anyNamed('playlist'),
            ),
          );
        },
        expect: () => [],
      );

      blocTest<PlaylistBloc, PlaylistState>(
        'does not call repository when the music sheet is not part of the current playlist',
        build: () => bloc,
        seed: () => PlaylistLoadedState(isLoading: false, playlist: testPlaylist),
        act: (bloc) => bloc.add(
          UpdateMusicSheetTranspositionEvent(
            musicSheet: MusicSheet(
              json: {
                MusicSheetKey.musicSheetId: 'sheet_not_in_playlist',
                MusicSheetKey.userId: 'user1',
                MusicSheetKey.createdAt: testTimestamp,
                MusicSheetKey.fileUrl: 'https://example.com/other.musicxml',
                MusicSheetKey.fileName: 'Other Sheet',
                MusicSheetKey.originalFileStorageId: 'storage2',
                MusicSheetKey.mediaType: 'musicxml',
                MusicSheetKey.sequenceId: 2,
              },
            ),
            transposition: 3,
          ),
        ),
        verify: (_) {
          verifyNever(
            mockFirebaseFirestoreRepository.updateMusicSheetTransposition(
              musicSheet: anyNamed('musicSheet'),
              transposition: anyNamed('transposition'),
              playlist: anyNamed('playlist'),
            ),
          );
        },
        expect: () => [],
      );
    });

    // Tests for SaveExportedPlaylistEvent are omitted because FilePicker
    // requires platform channels that are not available in unit tests.
  });
}
