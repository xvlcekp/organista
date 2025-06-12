import 'package:bloc/bloc.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:equatable/equatable.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:flutter/material.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/services/stream_manager.dart';
import 'dart:async';

part 'playlist_event.dart';
part 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final FirebaseFirestoreRepository firebaseFirestoreRepository;
  final FirebaseStorageRepository firebaseStorageRepository;
  StreamSubscription<Playlist>? _playlistSubscription;

  PlaylistBloc({
    required this.firebaseFirestoreRepository,
    required this.firebaseStorageRepository,
  }) : super(PlaylistInitState()) {
    on<UploadNewMusicSheetEvent>(_uploadNewMusicSheetEvent);
    on<DeleteMusicSheetInPlaylistEvent>(_deleteMusicSheetInPlaylistEvent);
    on<ReorderMusicSheetEvent>(_reorderMusicSheetEvent);
    on<RenameMusicSheetInPlaylistEvent>(_renameMusicSheetInPlaylistEvent);
    on<AddMusicSheetToPlaylistEvent>(_addMusicSheetToPlaylistEvent);
    on<InitPlaylistEvent>(_initPlaylistEvent);
    on<UpdatePlaylistEvent>(_onUpdatePlaylist);
  }

  void _uploadNewMusicSheetEvent(event, emit) async {
    emit(PlaylistLoadedState(
      isLoading: true,
      playlist: state.playlist,
    ));

    final MusicSheetFile file = event.file;
    final String fileName = event.fileName;
    final AuthUser user = event.user;
    final String repositoryId = event.repositoryId;

    try {
      final Reference? reference = await firebaseStorageRepository.uploadFile(
        file: file,
        bucket: user.id,
      );

      if (reference != null) {
        await firebaseFirestoreRepository.uploadMusicSheetRecord(
          reference: reference,
          userId: user.id,
          fileName: fileName,
          mediaType: file.mediaType,
          repositoryId: repositoryId,
        );
        emit(PlaylistLoadedState(
          isLoading: false,
          playlist: state.playlist,
        ));
      } else {
        throw Exception('Failed to upload file, not uploading MusicSheet record to Firestore');
      }
    } catch (e) {
      logger.e('Failed to upload file: $e');
      emit(PlaylistLoadedState(
        isLoading: false,
        playlist: state.playlist,
      ));
    }
  }

  void _deleteMusicSheetInPlaylistEvent(event, emit) async {
    emit(PlaylistLoadedState(
      isLoading: true,
      playlist: state.playlist,
    ));

    final MusicSheet musicSheetToDelete = event.musicSheet;
    final Playlist playlist = event.playlist;

    await firebaseFirestoreRepository.deleteMusicSheetInPlaylist(
      musicSheet: musicSheetToDelete,
      playlist: playlist,
    );
  }

  void _reorderMusicSheetEvent(event, emit) async {
    emit(PlaylistLoadedState(
      isLoading: true,
      playlist: state.playlist,
    ));
    await firebaseFirestoreRepository.musicSheetReorder(playlist: event.playlist);
  }

  void _renameMusicSheetInPlaylistEvent(event, emit) async {
    final musicSheet = event.musicSheet;
    final fileName = event.fileName;
    final playlist = event.playlist;
    await firebaseFirestoreRepository.renameMusicSheetInPlaylist(
      musicSheet: musicSheet,
      fileName: fileName,
      playlist: playlist,
    );
  }

  void _initPlaylistEvent(event, emit) async {
    logger.i("Init playlist was called");
    emit(PlaylistLoadedState(
      isLoading: true,
      playlist: event.playlist,
    ));

    try {
      final broadcastStream = StreamManager.instance.getBroadcastStream<Playlist>(
        'playlist_${event.playlist.playlistId}',
        () => firebaseFirestoreRepository.getPlaylistStream(event.playlist.playlistId),
      );

      // Always subscribe to the broadcast stream (even if reusing existing stream)
      _playlistSubscription = broadcastStream.listen(
        (playlist) {
          add(UpdatePlaylistEvent(playlist: playlist));
        },
        onError: (error) {
          logger.e('Error in playlist stream: $error');
          add(UpdatePlaylistEvent(playlist: Playlist.empty(), errorMessage: "Error on initialization"));
        },
      );

      logger.d('Subscribed to playlist stream: ${event.playlist.playlistId}');
    } catch (e) {
      logger.e('Error initializing playlist stream: $e');
      add(UpdatePlaylistEvent(playlist: Playlist.empty(), errorMessage: "Error initializing playlist"));
    }
  }

  void _onUpdatePlaylist(UpdatePlaylistEvent event, Emitter<PlaylistState> emit) {
    if (event.errorMessage != null) {
      emit(PlaylistErrorState(errorMessage: event.errorMessage!));
    } else {
      emit(PlaylistLoadedState(
        isLoading: false,
        playlist: event.playlist,
      ));
    }
  }

  void _addMusicSheetToPlaylistEvent(event, emit) async {
    final Playlist playlist = event.playlist;
    final MusicSheet musicSheet = event.musicSheet;
    final String fileName = event.fileName;

    emit(PlaylistLoadedState(
      isLoading: true,
      playlist: state.playlist,
    ));

    if (!state.playlist.musicSheets.any((sheet) => sheet.musicSheetId == musicSheet.musicSheetId)) {
      MusicSheet customNamedMusicSheet = musicSheet.copyWith(fileName: fileName);
      await firebaseFirestoreRepository.addMusicSheetToPlaylist(
        playlist: playlist,
        musicSheet: customNamedMusicSheet,
      );
    } else {
      // TODO: fix translations here, fix showing repositories after error message
      emit(PlaylistLoadedState(
        isLoading: false,
        playlist: state.playlist,
        errorMessage: 'Music sheet already exists in the playlist.',
      ));
    }
  }

  @override
  Future<void> close() {
    // Cancel the subscription when leaving the page for optimization
    // Cached values will be available when returning
    // Note: StreamManager handles removeListener automatically via onCancel
    _playlistSubscription?.cancel();
    return super.close();
  }
}
