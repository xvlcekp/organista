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
  const MusicSheetAlreadyInPlaylistError() : super();
}

@immutable
class InitializationError extends PlaylistError {
  const InitializationError() : super();
}
