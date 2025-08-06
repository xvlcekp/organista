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
class MusicSheetAlreadyInPlaylistError extends PlaylistError {
  final String musicSheetName;
  final String playlistName;
  const MusicSheetAlreadyInPlaylistError({required this.musicSheetName, required this.playlistName}) : super();
}

@immutable
class InitializationError extends PlaylistError {
  const InitializationError() : super();
}
