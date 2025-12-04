import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart' show immutable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/managers/stream_manager.dart';

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
      'playlists_$userId',
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

  void addPlaylist({required String playlistName, required String userId}) async {
    await _firebaseFirestoreRepository.addNewPlaylist(playlistName: playlistName, userId: userId);
  }

  void editPlaylistName({required String newPlaylistName, required Playlist playlist}) async {
    await _firebaseFirestoreRepository.renamePlaylist(newPlaylistName: newPlaylistName, playlist: playlist);
  }

  void deletePlaylist({required Playlist playlist}) async {
    await _firebaseFirestoreRepository.deletePlaylist(playlist: playlist);
  }
}
