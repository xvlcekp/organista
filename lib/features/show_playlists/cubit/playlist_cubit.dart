import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

part 'playlist_state.dart';

class PlaylistCubit extends Cubit<PlaylistState> {
  final FirebaseFirestoreRepository firebaseFirestoreRepositary;
  PlaylistCubit({
    required this.firebaseFirestoreRepositary,
  }) : super(const InitPlaylistState());

  late final StreamSubscription<Iterable<Playlist>> _streamSubscription;

  void resetState() {
    emit(const InitPlaylistState());
  }

  void startSubscribingPlaylists({required String userId}) async {
    _streamSubscription = firebaseFirestoreRepositary.getPlaylistsStream(userId).listen((playlists) {
      emit(PlaylistsLoadedState(playlists: playlists.toList()));
    });
  }

  @override
  Future<void> close() {
    _streamSubscription.cancel();
    return super.close();
  }

  void addPlaylist({required String playlistName, required String userId}) async {
    await firebaseFirestoreRepositary.addNewPlaylist(playlistName: playlistName, userId: userId);
  }

  void editPlaylistName({required String playlistName, required Playlist playlist}) {
    emit(EditPlaylistState(
      newPlaylistName: playlistName,
      playlist: playlist,
    ));
  }
}
