part of 'add_edit_music_sheet_cubit.dart';

@immutable
sealed class AddEditMusicSheetState extends Equatable {
  const AddEditMusicSheetState({
    required this.fileName,
  });

  final String fileName;
}

@immutable
class InitMusicSheetState extends AddEditMusicSheetState {
  const InitMusicSheetState() : super(fileName: "");

  @override
  List<Object?> get props => [fileName];
}

@immutable
class UploadMusicSheetState extends AddEditMusicSheetState {
  final File file;
  UploadMusicSheetState({
    required this.file,
  }) : super(fileName: basename(file.path));

  @override
  List<Object?> get props => [file];
}

@immutable
class EditMusicSheetState extends AddEditMusicSheetState {
  final Playlist playlist;
  final MusicSheet musicSheet;
  EditMusicSheetState({
    required this.playlist,
    required this.musicSheet,
  }) : super(fileName: musicSheet.fileName);

  @override
  List<Object?> get props => [fileName, musicSheet];
}

@immutable
class AddMusicSheetToPlaylistState extends AddEditMusicSheetState {
  final MusicSheet musicSheet;
  AddMusicSheetToPlaylistState({
    required this.musicSheet,
  }) : super(fileName: musicSheet.fileName);

  @override
  List<Object?> get props => [fileName, musicSheet];
}
