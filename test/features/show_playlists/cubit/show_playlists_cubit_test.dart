import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
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
}
