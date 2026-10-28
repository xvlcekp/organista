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

/// The user already has the maximum number of playlists; creating or duplicating one is refused.
@immutable
class MaximumPlaylistsCountExceeded extends PlaylistError {
  final int maximumPlaylistsCount;
  const MaximumPlaylistsCountExceeded({required this.maximumPlaylistsCount}) : super();
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

/// The device is offline and at least one of the sheets to add is not on the device, so it could not be shown.
@immutable
class PlaylistErrorNoInternet extends PlaylistError {
  const PlaylistErrorNoInternet() : super();
}

/// Error when export fails
@immutable
class ExportPlaylistError extends PlaylistError {
  const ExportPlaylistError() : super();
}

/// Export failed while the device was offline: a sheet that was never downloaded cannot be exported.
@immutable
class ExportPlaylistOfflineError extends PlaylistError {
  const ExportPlaylistOfflineError() : super();
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
