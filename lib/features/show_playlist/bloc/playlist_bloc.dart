import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show Uint8List, immutable;
import 'package:equatable/equatable.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';

part 'playlist_event.dart';
part 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  PlaylistBloc({
    required this.firebaseFirestoreRepositary,
    required this.firebaseStorageRepository,
  }) : super(PlaylistInitState()) {
    on<UploadImageMusicSheetEvent>(_uploadImageMusicSheetEvent);
    on<DeleteMusicSheetInPlaylistEvent>(_deleteMusicSheetInPlaylistEvent);
    on<ReorderMusicSheetEvent>(_reorderMusicSheetEvent);
    on<RenameMusicSheetInPlaylistEvent>(_renameMusicSheetInPlaylistEvent);
    on<AddMusicSheetToPlaylistEvent>(_addMusicSheetToPlaylistEvent);
    on<InitPlaylistEvent>(_initPlaylistEvent);
  }

  final FirebaseFirestoreRepository firebaseFirestoreRepositary;
  final FirebaseStorageRepository firebaseStorageRepository;

  void _uploadImageMusicSheetEvent(event, emit) async {
    // start the loading process
    emit(
      PlaylistLoadedState(
        isLoading: true,
        playlist: state.playlist,
      ),
    );
    // upload the file
    final file = event.file;
    final fileName = event.fileName;
    final user = event.user;
    try {
      final Reference? reference = await firebaseStorageRepository.uploadImage(
        file: file,
        userId: user.uid,
      );
      if (reference != null) {
        await firebaseFirestoreRepositary.uploadMusicSheetRecord(
          reference: reference,
          userId: user.uid,
          fileName: fileName,
        );
        emit(PlaylistLoadedState(
          isLoading: false,
          playlist: state.playlist,
        ));
      } else {
        throw Exception('Failed to upload image, not uploading MusicSheet record to Firestore');
      }
    } catch (e) {
      CustomLogger.instance.e('Failed to upload image: $e');
      emit(
        PlaylistLoadedState(
          isLoading: false,
          playlist: state.playlist,
        ),
      );
    }
  }

  void _deleteMusicSheetInPlaylistEvent(event, emit) async {
    emit(
      PlaylistLoadedState(
        isLoading: true,
        playlist: state.playlist,
      ),
    );
    // remove the file
    final MusicSheet musicSheetToDelete = event.musicSheet;
    final Playlist playlist = event.playlist;
    // TODO: we don't want to remove image globally
    // Reference imageToDelete = firebaseStorageRepository.getReference(musicSheetToDelete.originalFileStorageId);
    // await firebaseFirestoreRepositary.removeImage(file: imageToDelete);
    await firebaseFirestoreRepositary.deleteMusicSheetInPlaylist(
      musicSheet: musicSheetToDelete,
      playlist: playlist,
    );
  }

  void _reorderMusicSheetEvent(event, emit) async {
    emit(PlaylistLoadedState(
      isLoading: true,
      playlist: state.playlist,
    ));
    await firebaseFirestoreRepositary.musicSheetReorder(playlist: event.playlist);
  }

  void _renameMusicSheetInPlaylistEvent(event, emit) async {
    final musicSheet = event.musicSheet;
    final fileName = event.fileName;
    final playlist = event.playlist;
    await firebaseFirestoreRepositary.renameMusicSheetInPlaylist(
      musicSheet: musicSheet,
      fileName: fileName,
      playlist: playlist,
    );
  }

  void _initPlaylistEvent(event, emit) async {
    logger.e("Init playlist was called");
    emit(PlaylistLoadedState(
      isLoading: true,
      playlist: event.playlist,
    ));

    await emit.forEach<Playlist>(
      firebaseFirestoreRepositary.getPlaylistStream(event.playlist.playlistId),
      onData: (Playlist playlist) => PlaylistLoadedState(
        isLoading: false,
        playlist: playlist,
      ),
      onError: (_, __) => PlaylistErrorState(),
    );
  }

  void _addMusicSheetToPlaylistEvent(event, emit) async {
    final playlist = event.playlist;
    final musicSheet = event.musicSheet;
    final fileName = event.fileName;
    emit(PlaylistLoadedState(
      isLoading: true,
      playlist: state.playlist,
    ));
    // TODO: fix adding music sheet with new name
    await firebaseFirestoreRepositary.addMusicSheetToPlaylist(
      playlist: playlist,
      musicSheet: musicSheet,
    );
  }
}
