import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

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

  void startSubscribingPlaylists({required String userId}) async {
    _streamSubscription = firebaseFirestoreRepository.getPlaylistsStream(userId).listen((playlists) {
      emit(PlaylistsLoadedState(playlists: playlists.toList()));
    });
  }

  @override
  Future<void> close() {
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
