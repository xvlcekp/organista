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
  String? _currentStreamIdentifier;

  void resetState() {
    emit(const InitPlaylistState());
  }

  void startSubscribingPlaylists({required String userId}) {
    final streamIdentifier = 'playlists_$userId';

    // Only remove listener if we're switching to a different stream
    if (_currentStreamIdentifier != null && _currentStreamIdentifier != streamIdentifier) {
      StreamManager.instance.removeListener(_currentStreamIdentifier!);
    }

    _currentStreamIdentifier = streamIdentifier;

    final broadcastStream = StreamManager.instance.getBroadcastStream<Iterable<Playlist>>(
      streamIdentifier,
      () => firebaseFirestoreRepository.getPlaylistsStream(userId),
    );

    // Always subscribe to the broadcast stream (even if reusing existing stream)
    _streamSubscription = broadcastStream.listen((playlists) {
      emit(PlaylistsLoadedState(playlists: playlists.toList()));
    });

    logger.d('Subscribed to broadcast stream for playlists of user: $userId');
  }

  @override
  Future<void> close() {
    // Only remove the listener from StreamManager, never cancel subscriptions
    // Streams will only be canceled on logout/user deletion via StreamManager.cancelAllStreams()
    if (_currentStreamIdentifier != null) {
      StreamManager.instance.removeListener(_currentStreamIdentifier!);
    }
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
