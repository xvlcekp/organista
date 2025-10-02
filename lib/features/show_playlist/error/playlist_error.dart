import 'package:flutter/foundation.dart';

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
class InitializationError extends PlaylistError {
  const InitializationError() : super();
}
