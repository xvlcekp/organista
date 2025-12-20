import 'package:flutter/foundation.dart';
import 'package:organista/models/playlists/playlist.dart';

@immutable
abstract class PlaylistError {
  const PlaylistError();
}

@immutable
class PlaylistErrorUnknown extends PlaylistError {
  const PlaylistErrorUnknown() : super();
}

@immutable
class MusicSheetsAlreadyInPlaylistError extends PlaylistError {
  final List<String> duplicateMusicSheetNames;
  final String playlistName;
  const MusicSheetsAlreadyInPlaylistError({required this.duplicateMusicSheetNames, required this.playlistName})
    : super();
}

@immutable
class PlaylistCapacityExceededError extends PlaylistError {
  final Playlist playlist;
  final int attemptedToAdd;
  final int maxCapacity;

  const PlaylistCapacityExceededError({
    required this.playlist,
    required this.attemptedToAdd,
    required this.maxCapacity,
  }) : super();
}

@immutable
class InitializationError extends PlaylistError {
  const InitializationError() : super();
}

/// Error when trying to export a playlist with no music sheets
@immutable
class ExportNoMusicSheetsPlaylistError extends PlaylistError {
  const ExportNoMusicSheetsPlaylistError() : super();
}

/// Error when export fails
@immutable
class ExportPlaylistError extends PlaylistError {
  const ExportPlaylistError() : super();
}

/// Error when source file does not exist
@immutable
class SourceFileNotFoundPlaylistError extends PlaylistError {
  const SourceFileNotFoundPlaylistError() : super();
}

/// Error when saving file fails
@immutable
class ExportSaveFailedPlaylistError extends PlaylistError {
  final String exceptionMessage;
  const ExportSaveFailedPlaylistError({required this.exceptionMessage}) : super();
}
