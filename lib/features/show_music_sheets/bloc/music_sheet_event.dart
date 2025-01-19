part of 'music_sheet_bloc.dart';

@immutable
abstract class MusicSheetEvent {
  const MusicSheetEvent();
}

@immutable
class InitMusicSheetEvent implements MusicSheetEvent {
  final User user;
  const InitMusicSheetEvent({
    required this.user,
  });
}

@immutable
class UploadImageMusicSheetEvent implements MusicSheetEvent {
  final User user;
  final Uint8List file;
  final String fileName;

  const UploadImageMusicSheetEvent({
    required this.user,
    required this.file,
    required this.fileName,
  });
}

@immutable
class RenameMusicSheetEvent implements MusicSheetEvent {
  final MusicSheet musicSheet;
  final String fileName;

  const RenameMusicSheetEvent({
    required this.musicSheet,
    required this.fileName,
  });
}

@immutable
class DeleteMusicSheetEvent implements MusicSheetEvent {
  final MusicSheet musicSheet;

  const DeleteMusicSheetEvent({
    required this.musicSheet,
  });
}

@immutable
class ReorderMusicSheetEvent implements MusicSheetEvent {
  final Iterable<MusicSheet> musicSheets;

  const ReorderMusicSheetEvent({
    required this.musicSheets,
  });
}
