import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/services/stream_manager.dart';

part 'playlists_state.dart';

class ShowPlaylistsCubit extends Cubit<ShowPlaylistsState> {
  final FirebaseFirestoreRepository firebaseFirestoreRepository;
  ShowPlaylistsCubit({
    required this.firebaseFirestoreRepository,
  }) : super(const InitPlaylistState());

  late final StreamSubscription<Iterable<Playlist>> _streamSubscription;

  void resetState() {
    emit(const InitPlaylistState());
  }

  void startSubscribingPlaylists({required String userId}) {
    final broadcastStream = StreamManager.instance.getBroadcastStream<Iterable<Playlist>>(
      'playlists_$userId',
      () => firebaseFirestoreRepository.getPlaylistsStream(userId),
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
    _streamSubscription.cancel();
    return super.close();
  }

  void addPlaylist({required String playlistName, required String userId}) async {
    await firebaseFirestoreRepository.addNewPlaylist(playlistName: playlistName, userId: userId);
  }

  void editPlaylistName({required String newPlaylistName, required Playlist playlist}) async {
    await firebaseFirestoreRepository.renamePlaylist(newPlaylistName: newPlaylistName, playlist: playlist);
  }

  void deletePlaylist({required Playlist playlist}) async {
    await firebaseFirestoreRepository.deletePlaylist(playlist: playlist);
  }
}
