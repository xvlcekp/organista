part of 'playlist_bloc.dart';

@immutable
abstract class PlaylistEvent {
  const PlaylistEvent();
}

@immutable
class InitPlaylistEvent implements PlaylistEvent {
  final User user;
  final Playlist playlist;
  const InitPlaylistEvent({required this.user, required this.playlist});
}

@immutable
class UploadNewMusicSheetEvent implements PlaylistEvent {
  final User user;
  final PlatformFile file;
  final String fileName;
  final String repositoryId;

  const UploadNewMusicSheetEvent({
    required this.user,
    required this.file,
    required this.fileName,
    required this.repositoryId,
  });
}

@immutable
class RenameMusicSheetInPlaylistEvent implements PlaylistEvent {
  final Playlist playlist;
  final MusicSheet musicSheet;
  final String fileName;

  const RenameMusicSheetInPlaylistEvent({
    required this.playlist,
    required this.musicSheet,
    required this.fileName,
  });
}

@immutable
class DeleteMusicSheetInPlaylistEvent implements PlaylistEvent {
  final MusicSheet musicSheet;
  final Playlist playlist;

  const DeleteMusicSheetInPlaylistEvent({
    required this.musicSheet,
    required this.playlist,
  });
}

@immutable
class ReorderMusicSheetEvent implements PlaylistEvent {
  final Playlist playlist;

  const ReorderMusicSheetEvent({
    required this.playlist,
  });
}

@immutable
class AddMusicSheetToPlaylistEvent implements PlaylistEvent {
  final MusicSheet musicSheet;
  final String fileName;
  final Playlist playlist;

  const AddMusicSheetToPlaylistEvent({
    required this.musicSheet,
    required this.fileName,
    required this.playlist,
  });
}
