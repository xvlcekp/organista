import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
import 'package:organista/features/show_playlists/cubit/playlist_sort.dart';
import 'package:organista/features/show_playlists/cubit/show_playlists_cubit.dart';
import 'package:organista/managers/stream_identifier.dart';
import 'package:organista/managers/stream_manager.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/models/playlists/playlist_key.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

class MockFirebaseFirestoreRepository extends Mock implements FirebaseFirestoreRepository {}

void main() {
  late MockFirebaseFirestoreRepository repository;

  const userId = 'user-1';
  final playlist = Playlist(
    playlistId: 'playlist-1',
    json: const {PlaylistKey.userId: userId, PlaylistKey.name: 'Sunday Service', PlaylistKey.musicSheets: []},
  );

  setUp(() {
    repository = MockFirebaseFirestoreRepository();
    registerFallbackValue(playlist);
  });

  tearDown(() async {
    await StreamManager.instance.cancelAllStreams();
  });

  group('ShowPlaylistsCubit.deletePlaylist', () {
    test('stops the playlist document stream before deleting the document', () async {
      // The owner-only read rule evaluates `resource.data` and therefore fails for a document that no longer
      // exists, so a listener that is still open when the playlist is deleted would receive permission-denied.
      final source = StreamController<Playlist>();
      final identifier = StreamIdentifier.playlist(playlist.playlistId);
      final subscription = StreamManager.instance
          .getBroadcastStream<Playlist>(identifier, () => source.stream)
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(StreamManager.instance.getStats()['streamIdentifiers'], contains(identifier));

      List<String>? activeStreamsAtDelete;
      when(() => repository.deletePlaylist(playlist: playlist)).thenAnswer((_) async {
        activeStreamsAtDelete = List<String>.from(StreamManager.instance.getStats()['streamIdentifiers'] as List);
        return true;
      });

      await ShowPlaylistsCubit(firebaseFirestoreRepository: repository).deletePlaylist(playlist: playlist);

      expect(activeStreamsAtDelete, isNotNull, reason: 'the repository delete must still be called');
      expect(activeStreamsAtDelete, isNot(contains(identifier)));

      await subscription.cancel();
      await source.close();
    });
  });

  group('ShowPlaylistsCubit write failures', () {
    final seed = PlaylistsLoadedState(playlists: [playlist]);
    final failed = PlaylistsLoadedState(playlists: [playlist], error: const PlaylistErrorUnknown());

    blocTest<ShowPlaylistsCubit, ShowPlaylistsState>(
      'addPlaylist reports the error and clears it again when the repository could not save the playlist',
      setUp: () => when(
        () => repository.addNewPlaylist(playlistName: 'Advent', userId: userId),
      ).thenAnswer((_) async => false),
      build: () => ShowPlaylistsCubit(firebaseFirestoreRepository: repository),
      seed: () => seed,
      act: (cubit) => cubit.addPlaylist(playlistName: 'Advent', userId: userId),
      // The error is cleared right away so that the next failure produces a new state (Equatable would
      // otherwise swallow an identical consecutive error state and the dialog would not show again).
      expect: () => [failed, seed],
    );

    blocTest<ShowPlaylistsCubit, ShowPlaylistsState>(
      'editPlaylistName reports the error when the repository could not rename the playlist',
      setUp: () => when(
        () => repository.renamePlaylist(newPlaylistName: 'Renamed', playlist: playlist),
      ).thenAnswer((_) async => false),
      build: () => ShowPlaylistsCubit(firebaseFirestoreRepository: repository),
      seed: () => seed,
      act: (cubit) => cubit.editPlaylistName(newPlaylistName: 'Renamed', playlist: playlist),
      expect: () => [failed, seed],
    );

    blocTest<ShowPlaylistsCubit, ShowPlaylistsState>(
      'duplicatePlaylist reports the error when the repository could not create the copy',
      setUp: () => when(
        () => repository.duplicatePlaylist(playlist: playlist, newPlaylistName: 'Sunday Service (copy)'),
      ).thenAnswer((_) async => false),
      build: () => ShowPlaylistsCubit(firebaseFirestoreRepository: repository),
      seed: () => seed,
      act: (cubit) => cubit.duplicatePlaylist(newPlaylistName: 'Sunday Service (copy)', playlist: playlist),
      expect: () => [failed, seed],
    );

    blocTest<ShowPlaylistsCubit, ShowPlaylistsState>(
      'duplicatePlaylist emits nothing when the copy is written (the playlists stream delivers the new list)',
      setUp: () => when(
        () => repository.duplicatePlaylist(playlist: playlist, newPlaylistName: 'Sunday Service (copy)'),
      ).thenAnswer((_) async => true),
      build: () => ShowPlaylistsCubit(firebaseFirestoreRepository: repository),
      seed: () => seed,
      act: (cubit) => cubit.duplicatePlaylist(newPlaylistName: 'Sunday Service (copy)', playlist: playlist),
      expect: () => <ShowPlaylistsState>[],
      verify: (_) => verify(
        () => repository.duplicatePlaylist(playlist: playlist, newPlaylistName: 'Sunday Service (copy)'),
      ).called(1),
    );

    blocTest<ShowPlaylistsCubit, ShowPlaylistsState>(
      'deletePlaylist reports the error when the repository could not delete the playlist',
      setUp: () => when(() => repository.deletePlaylist(playlist: playlist)).thenAnswer((_) async => false),
      build: () => ShowPlaylistsCubit(firebaseFirestoreRepository: repository),
      seed: () => seed,
      act: (cubit) => cubit.deletePlaylist(playlist: playlist),
      expect: () => [failed, seed],
    );

    blocTest<ShowPlaylistsCubit, ShowPlaylistsState>(
      'addPlaylist emits nothing when the write succeeds (the playlists stream delivers the new list)',
      setUp: () => when(
        () => repository.addNewPlaylist(playlistName: 'Advent', userId: userId),
      ).thenAnswer((_) async => true),
      build: () => ShowPlaylistsCubit(firebaseFirestoreRepository: repository),
      seed: () => seed,
      act: (cubit) => cubit.addPlaylist(playlistName: 'Advent', userId: userId),
      expect: () => <ShowPlaylistsState>[],
    );
  });

  group('ShowPlaylistsCubit search and sort', () {
    Playlist makePlaylist(String id, String name, DateTime createdAt, {DateTime? modifiedAt}) => Playlist(
      playlistId: id,
      json: {
        PlaylistKey.userId: userId,
        PlaylistKey.name: name,
        PlaylistKey.createdAt: Timestamp.fromDate(createdAt),
        if (modifiedAt != null) PlaylistKey.modifiedAt: Timestamp.fromDate(modifiedAt),
        PlaylistKey.musicSheets: const [],
      },
    );

    // Stream order is by name, which is what the server delivers.
    final advent = makePlaylist('p1', 'Advent', DateTime(2024, 12, 1));
    final funeral = makePlaylist('p2', 'Pohreb', DateTime(2025, 3, 5));
    final wedding = makePlaylist('p3', 'Svadba Žilina', DateTime(2025, 1, 20));
    final byName = [advent, funeral, wedding];

    test('visiblePlaylists keeps the stream order when nothing is searched or sorted', () {
      final state = PlaylistsLoadedState(playlists: byName);
      expect(state.visiblePlaylists, byName);
    });

    blocTest<ShowPlaylistsCubit, ShowPlaylistsState>(
      'search filters by name ignoring case and diacritics',
      build: () => ShowPlaylistsCubit(firebaseFirestoreRepository: repository),
      seed: () => PlaylistsLoadedState(playlists: byName),
      act: (cubit) => cubit.search('zilina'),
      verify: (cubit) {
        expect(cubit.state.searchQuery, 'zilina');
        expect(cubit.state.visiblePlaylists, [wedding]);
      },
    );

    blocTest<ShowPlaylistsCubit, ShowPlaylistsState>(
      'sortBy newest puts the most recently created playlist first',
      build: () => ShowPlaylistsCubit(firebaseFirestoreRepository: repository),
      seed: () => PlaylistsLoadedState(playlists: byName),
      act: (cubit) => cubit.sortBy(PlaylistSort.newest),
      verify: (cubit) {
        expect(cubit.state.sort, PlaylistSort.newest);
        expect(cubit.state.visiblePlaylists, [funeral, wedding, advent]);
      },
    );

    blocTest<ShowPlaylistsCubit, ShowPlaylistsState>(
      'sortBy modified puts the most recently changed playlist first, old playlists counting as changed on creation',
      build: () => ShowPlaylistsCubit(firebaseFirestoreRepository: repository),
      // Advent is the oldest but was edited last; Pohreb was never edited since modifiedAt existed.
      seed: () => PlaylistsLoadedState(
        playlists: [
          makePlaylist('p1', 'Advent', DateTime(2024, 12, 1), modifiedAt: DateTime(2025, 4, 1)),
          funeral,
          wedding,
        ],
      ),
      act: (cubit) => cubit.sortBy(PlaylistSort.modified),
      verify: (cubit) => expect(cubit.state.visiblePlaylists.map((p) => p.name), ['Advent', 'Pohreb', 'Svadba Žilina']),
    );

    blocTest<ShowPlaylistsCubit, ShowPlaylistsState>(
      'sortBy name restores the stream order',
      build: () => ShowPlaylistsCubit(firebaseFirestoreRepository: repository),
      seed: () => PlaylistsLoadedState(playlists: byName, sort: PlaylistSort.newest),
      act: (cubit) => cubit.sortBy(PlaylistSort.name),
      verify: (cubit) => expect(cubit.state.visiblePlaylists, byName),
    );

    test('a new list from the playlists stream keeps the search query and sort', () async {
      final source = StreamController<Iterable<Playlist>>();
      when(() => repository.getPlaylistsStream(userId)).thenAnswer((_) => source.stream);
      final cubit = ShowPlaylistsCubit(firebaseFirestoreRepository: repository)
        ..startSubscribingPlaylists(userId: userId)
        ..search('a')
        ..sortBy(PlaylistSort.newest);

      source.add(byName);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.searchQuery, 'a');
      expect(cubit.state.sort, PlaylistSort.newest);
      expect(cubit.state.visiblePlaylists, [wedding, advent]);

      await cubit.close();
      await source.close();
    });

    blocTest<ShowPlaylistsCubit, ShowPlaylistsState>(
      'a reported write failure keeps the search query and sort',
      setUp: () => when(() => repository.deletePlaylist(playlist: advent)).thenAnswer((_) async => false),
      build: () => ShowPlaylistsCubit(firebaseFirestoreRepository: repository),
      seed: () => PlaylistsLoadedState(playlists: byName, searchQuery: 'a', sort: PlaylistSort.newest),
      act: (cubit) => cubit.deletePlaylist(playlist: advent),
      expect: () => [
        PlaylistsLoadedState(
          playlists: byName,
          searchQuery: 'a',
          sort: PlaylistSort.newest,
          error: const PlaylistErrorUnknown(),
        ),
        PlaylistsLoadedState(playlists: byName, searchQuery: 'a', sort: PlaylistSort.newest),
      ],
    );
  });
}
