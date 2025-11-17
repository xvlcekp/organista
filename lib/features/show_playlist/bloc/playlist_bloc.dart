import 'package:bloc/bloc.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:meta/meta.dart' show immutable;
import 'package:equatable/equatable.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/services/stream_manager.dart';
import 'dart:async';

part 'playlist_event.dart';
part 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final FirebaseFirestoreRepository _firebaseFirestoreRepository;
  final FirebaseStorageRepository _firebaseStorageRepository;
  StreamSubscription<Playlist>? _playlistSubscription;

  PlaylistBloc({
    required FirebaseFirestoreRepository firebaseFirestoreRepository,
    required FirebaseStorageRepository firebaseStorageRepository,
  }) : _firebaseStorageRepository = firebaseStorageRepository,
       _firebaseFirestoreRepository = firebaseFirestoreRepository,
       super(PlaylistInitState()) {
    on<UploadNewMusicSheetEvent>(_uploadNewMusicSheetEvent);
    on<DeleteMusicSheetInPlaylistEvent>(_deleteMusicSheetInPlaylistEvent);
    on<ReorderMusicSheetEvent>(_reorderMusicSheetEvent);
    on<RenameMusicSheetInPlaylistEvent>(_renameMusicSheetInPlaylistEvent);
    on<AddMusicSheetsToPlaylistEvent>(_addMusicSheetsToPlaylistEvent);
    on<InitPlaylistEvent>(_initPlaylistEvent);
    on<UpdatePlaylistEvent>(_onUpdatePlaylist);
  }

  void _uploadNewMusicSheetEvent(UploadNewMusicSheetEvent event, Emitter<PlaylistState> emit) async {
    emit(
      PlaylistLoadedState(
        isLoading: true,
        playlist: state.playlist,
      ),
    );

    final MusicSheetFile file = event.file;
    final String fileName = event.fileName;
    final AuthUser user = event.user;
    final String repositoryId = event.repositoryId;

    try {
      final Reference? reference = await _firebaseStorageRepository.uploadFile(
        file: file,
        bucket: user.id,
      );

      if (reference != null) {
        await _firebaseFirestoreRepository.uploadMusicSheetRecord(
          reference: reference,
          userId: user.id,
          fileName: fileName,
          mediaType: file.mediaType,
          repositoryId: repositoryId,
        );
        emit(
          PlaylistLoadedState(
            isLoading: false,
            playlist: state.playlist,
          ),
        );
      } else {
        throw Exception('Failed to upload file, not uploading MusicSheet record to Firestore');
      }
    } catch (e) {
      logger.e('Failed to upload file: $e');
      emit(
        PlaylistLoadedState(
          isLoading: false,
          playlist: state.playlist,
        ),
      );
    }
  }

  void _deleteMusicSheetInPlaylistEvent(DeleteMusicSheetInPlaylistEvent event, Emitter<PlaylistState> emit) async {
    emit(
      PlaylistLoadedState(
        isLoading: true,
        playlist: state.playlist,
      ),
    );

    final MusicSheet musicSheetToDelete = event.musicSheet;
    final Playlist playlist = event.playlist;

    await _firebaseFirestoreRepository.deleteMusicSheetInPlaylist(
      musicSheet: musicSheetToDelete,
      playlist: playlist,
    );
  }

  void _reorderMusicSheetEvent(ReorderMusicSheetEvent event, Emitter<PlaylistState> emit) async {
    emit(
      PlaylistLoadedState(
        isLoading: true,
        playlist: state.playlist,
      ),
    );
    await _firebaseFirestoreRepository.musicSheetReorder(playlist: event.playlist);
  }

  void _renameMusicSheetInPlaylistEvent(RenameMusicSheetInPlaylistEvent event, Emitter<PlaylistState> emit) async {
    final musicSheet = event.musicSheet;
    final fileName = event.fileName;
    final playlist = event.playlist;
    await _firebaseFirestoreRepository.renameMusicSheetInPlaylist(
      musicSheet: musicSheet,
      fileName: fileName,
      playlist: playlist,
    );
  }

  void _initPlaylistEvent(InitPlaylistEvent event, Emitter<PlaylistState> emit) {
    logger.i("Init playlist was called");
    emit(
      PlaylistLoadedState(
        isLoading: true,
        playlist: event.playlist,
      ),
    );

    try {
      final playlistId = event.playlist.playlistId;
      final broadcastStream = StreamManager.instance.getBroadcastStream<Playlist>(
        'playlist_$playlistId',
        () => _firebaseFirestoreRepository.getPlaylistStream(event.playlist.playlistId),
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

      logger.d('Subscribed to playlist stream: $playlistId');
    } catch (e) {
      logger.e('Error initializing playlist stream: $e');
      add(UpdatePlaylistEvent(playlist: Playlist.empty(), errorMessage: "Error initializing playlist"));
    }
  }

  void _onUpdatePlaylist(UpdatePlaylistEvent event, Emitter<PlaylistState> emit) {
    if (event.errorMessage != null) {
      emit(PlaylistErrorState(errorMessage: event.errorMessage!));
    } else {
      emit(
        PlaylistLoadedState(
          isLoading: false,
          playlist: event.playlist,
        ),
      );
    }
  }

  void _addMusicSheetsToPlaylistEvent(
    AddMusicSheetsToPlaylistEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    final Playlist playlist = event.playlist;
    final List<MusicSheet> musicSheets = event.musicSheets;

    emit(
      PlaylistLoadedState(
        isLoading: true,
        playlist: state.playlist,
      ),
    );

    // Separate new music sheets from duplicates
    final duplicates = <MusicSheet>[];
    final newMusicSheets = <MusicSheet>[];

    // Create a Set of existing music sheet IDs for O(1) lookup
    final existingMusicSheetIds = state.playlist.musicSheets.map((sheet) => sheet.musicSheetId).toSet();

    for (final musicSheet in musicSheets) {
      if (existingMusicSheetIds.contains(musicSheet.musicSheetId)) {
        duplicates.add(musicSheet);
      } else {
        newMusicSheets.add(musicSheet);
      }
    }

    // Add new music sheets if any (repository will validate capacity)
    if (newMusicSheets.isNotEmpty) {
      try {
        await _firebaseFirestoreRepository.addMusicSheetsToPlaylist(
          playlist: playlist,
          musicSheets: newMusicSheets,
        );
      } on PlaylistCapacityExceededError catch (error) {
        emit(
          PlaylistLoadedState(
            isLoading: false,
            playlist: state.playlist,
            error: error,
          ),
        );
        return;
      }
    }

    // Handle duplicates feedback
    if (duplicates.isNotEmpty) {
      final error = MusicSheetsAlreadyInPlaylistError(
        duplicateMusicSheetNames: duplicates.map((sheet) => sheet.fileName).toList(),
        playlistName: playlist.name,
      );

      emit(
        PlaylistLoadedState(
          isLoading: false,
          playlist: state.playlist,
          error: error,
        ),
      );
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
