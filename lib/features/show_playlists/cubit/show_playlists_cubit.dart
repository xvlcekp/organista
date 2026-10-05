import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart' show immutable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/managers/stream_identifier.dart';
import 'package:organista/managers/stream_manager.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

part 'show_playlists_state.dart';

class ShowPlaylistsCubit extends Cubit<ShowPlaylistsState> {
  final FirebaseFirestoreRepository _firebaseFirestoreRepository;
  ShowPlaylistsCubit({
    required FirebaseFirestoreRepository firebaseFirestoreRepository,
  }) : _firebaseFirestoreRepository = firebaseFirestoreRepository,
       super(const InitPlaylistState());

  StreamSubscription<Iterable<Playlist>>? _streamSubscription;

  void resetState() {
    emit(const InitPlaylistState());
  }

  void startSubscribingPlaylists({required String userId}) {
    final broadcastStream = StreamManager.instance.getBroadcastStream<Iterable<Playlist>>(
      StreamIdentifier.playlists(userId),
      () => _firebaseFirestoreRepository.getPlaylistsStream(userId),
    );

    // Always subscribe to the broadcast stream (even if reusing existing stream)
    _streamSubscription = broadcastStream.listen((playlists) {
      emit(PlaylistsLoadedState(playlists: playlists.toList()));
    });

    logger.d('Subscribed to playlists stream for user: $userId');
  }

  @override
  Future<void> close() {
    // Cancel the subscription when leaving the page for optimization
    // Cached values will be available when returning
    // Note: StreamManager handles removeListener automatically via onCancel
    _streamSubscription?.cancel();
    return super.close();
  }

  Future<void> addPlaylist({required String playlistName, required String userId}) async {
    final written = await _firebaseFirestoreRepository.addNewPlaylist(playlistName: playlistName, userId: userId);
    _reportIfNotWritten(written);
  }

  Future<void> editPlaylistName({required String newPlaylistName, required Playlist playlist}) async {
    final written = await _firebaseFirestoreRepository.renamePlaylist(
      newPlaylistName: newPlaylistName,
      playlist: playlist,
    );
    _reportIfNotWritten(written);
  }

  Future<void> deletePlaylist({required Playlist playlist}) async {
    // Stop listening to the document first: the owner-only read rule fails for a deleted document, so an open
    // listener would otherwise receive permission-denied once the delete goes through.
    await StreamManager.instance.cancelStream(StreamIdentifier.playlist(playlist.playlistId));
    final written = await _firebaseFirestoreRepository.deletePlaylist(playlist: playlist);
    _reportIfNotWritten(written);
  }

  /// Shows a failed write (already logged by the repository). The error is cleared right away so that Equatable
  /// does not swallow the next identical one.
  void _reportIfNotWritten(bool written) {
    if (written || isClosed) {
      return;
    }
    final playlists = state.playlists;
    emit(PlaylistsLoadedState(playlists: playlists, error: const PlaylistErrorUnknown()));
    emit(PlaylistsLoadedState(playlists: playlists));
  }
}
