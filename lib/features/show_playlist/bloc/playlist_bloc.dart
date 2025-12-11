import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:meta/meta.dart' show immutable;
import 'package:organista/extensions/num_extensions.dart';
import 'package:organista/services/export_playlist/export_playlist_service.dart';
import 'package:organista/features/show_playlist/error/playlist_error.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/managers/stream_manager.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'playlist_event.dart';
part 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final FirebaseFirestoreRepository _firebaseFirestoreRepository;
  final ExportPlaylistService _exportService;

  PlaylistBloc({
    required FirebaseFirestoreRepository firebaseFirestoreRepository,
    required ExportPlaylistService exportService,
  }) : _firebaseFirestoreRepository = firebaseFirestoreRepository,
       _exportService = exportService,
       super(PlaylistInitState()) {
    on<DeleteMusicSheetInPlaylistEvent>(_deleteMusicSheetInPlaylistEvent);
    on<ReorderMusicSheetEvent>(_reorderMusicSheetEvent);
    on<AddMusicSheetsToPlaylistEvent>(_addMusicSheetsToPlaylistEvent);
    on<InitPlaylistEvent>(_initPlaylistEvent);
    on<ExportPlaylistEvent>(_exportPlaylistEvent);
    on<SaveExportedPlaylistEvent>(_saveExportedPlaylistEvent);
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

  Future<void> _initPlaylistEvent(InitPlaylistEvent event, Emitter<PlaylistState> emit) async {
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

      logger.d('Subscribed to playlist stream: $playlistId');

      // Use emit.forEach to keep the event handler alive while processing the stream
      await emit.forEach<Playlist>(
        broadcastStream,
        onData: (playlist) {
          return PlaylistLoadedState(
            isLoading: false,
            playlist: playlist,
          );
        },
        onError: (error, stackTrace) {
          logger.e('Error in playlist stream: $error');
          return PlaylistErrorState(error: const InitializationError(), playlist: state.playlist);
        },
      );
    } catch (e) {
      logger.e('Error initializing playlist stream: $e');
      emit(PlaylistErrorState(error: const InitializationError(), playlist: state.playlist));
    }
  }

  void _addMusicSheetsToPlaylistEvent(AddMusicSheetsToPlaylistEvent event, Emitter<PlaylistState> emit) async {
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
        emit(PlaylistErrorState(error: error, playlist: state.playlist));
        return;
      }
    }

    // Handle duplicates feedback
    if (duplicates.isNotEmpty) {
      final error = MusicSheetsAlreadyInPlaylistError(
        duplicateMusicSheetNames: duplicates.map((sheet) => sheet.fileName).toList(),
        playlistName: playlist.name,
      );
      emit(PlaylistErrorState(error: error, playlist: state.playlist));
    }
  }

  Future<void> _exportPlaylistEvent(ExportPlaylistEvent event, Emitter<PlaylistState> emit) async {
    final Playlist playlist = event.playlist;
    final List<MusicSheet> musicSheets = playlist.musicSheets;

    if (musicSheets.isEmpty) {
      emit(PlaylistErrorState(error: const ExportNoMusicSheetsPlaylistError(), playlist: playlist));
      return;
    }

    emit(PlaylistLoadedState(isLoading: true, playlist: playlist));

    final tempOutputPath = await _exportService.exportPlaylistToPdf(playlist: playlist);

    if (tempOutputPath == null) {
      emit(
        PlaylistErrorState(
          error: const ExportPlaylistError(),
          playlist: playlist,
        ),
      );
      return;
    }
    emit(
      PlaylistReadyToExportState(
        isLoading: false,
        playlist: playlist,
        tempPath: tempOutputPath,
        playlistName: playlist.name,
      ),
    );
  }

  /// Saves the exported file to user-selected location
  Future<void> _saveExportedPlaylistEvent(SaveExportedPlaylistEvent event, Emitter<PlaylistState> emit) async {
    final String tempPath = event.tempPath;
    final String fileName = event.fileName;
    emit(PlaylistLoadedState(isLoading: true, playlist: state.playlist));

    // Read file bytes first (required on Android/iOS)
    final sourceFile = File(tempPath);

    try {
      // Check if file exists and get size
      if (!await sourceFile.exists()) {
        logger.e('Source file does not exist: $tempPath');
        emit(
          PlaylistErrorState(
            error: const SourceFileNotFoundPlaylistError(),
            playlist: state.playlist,
          ),
        );
        return;
      }

      final fileSize = await sourceFile.length();
      logger.i('File size: ${fileSize.bytesToMegaBytes} MB');

      final bytes = await sourceFile.readAsBytes();
      logger.i('Read ${bytes.length} bytes from file');

      // Always show file picker to let user choose save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export to PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes, // Required on Android & iOS
      );

      logger.i('File picker result: $result');

      if (result != null && result.isNotEmpty) {
        // File was saved by file picker
        logger.i('File saved to user-selected location: $result');
        emit(
          PlaylistExportedState(isLoading: false, playlist: state.playlist),
        );
      } else {
        // User cancelled the file picker
        logger.i('User cancelled file picker');
        emit(PlaylistExportCancelledState(isLoading: false, playlist: state.playlist));
      }
    } catch (e, stackTrace) {
      logger.e('File picker save failed: $e');
      logger.e('Stack trace: $stackTrace');
      Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'temp_path': tempPath,
          'file_name': fileName,
        }),
      );
      // File picker failed, show error to user
      emit(
        PlaylistErrorState(
          error: ExportSaveFailedPlaylistError(exceptionMessage: e.toString()),
          playlist: state.playlist,
        ),
      );
    } finally {
      // Always try to clean up the temporary file after save operation completes
      await _cleanupTempFile(sourceFile);
    }
  }

  /// Cleans up the temporary file
  Future<void> _cleanupTempFile(File tempFile) async {
    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
        logger.i('Temporary file deleted: ${tempFile.path}');
      }
    } catch (e) {
      logger.w('Failed to delete temporary file: ${tempFile.path}, error: $e');
      // Don't throw - cleanup failure shouldn't break the flow
    }
  }
}
