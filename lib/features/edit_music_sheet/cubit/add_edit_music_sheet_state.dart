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
class AddMusicSheetState extends AddEditMusicSheetState {
  final Uint8List file;
  const AddMusicSheetState({
    required super.fileName,
    required this.file,
  });

  @override
  List<Object?> get props => [fileName, file];
}

@immutable
class EditMusicSheetState extends AddEditMusicSheetState {
  final MusicSheet musicSheet;
  const EditMusicSheetState({
    required super.fileName,
    required this.musicSheet,
  });

  @override
  List<Object?> get props => [fileName, musicSheet];
}
