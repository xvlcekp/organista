part of 'add_edit_music_sheet_cubit.dart';

@immutable
sealed class AddEditMusicSheetState extends Equatable {
  const AddEditMusicSheetState({
    required this.fileName,
    required this.isLoading,
    this.error,
  });

  final String fileName;
  final bool isLoading;
  final AddEditMusicSheetError? error;
}

@immutable
class InitMusicSheetState extends AddEditMusicSheetState {
  const InitMusicSheetState()
    : super(
        fileName: "",
        isLoading: false,
      );

  @override
  List<Object?> get props => [fileName, isLoading, error];
}

@immutable
class UploadMusicSheetState extends AddEditMusicSheetState {
  final MusicSheetFile file;
  final String repositoryId;
  UploadMusicSheetState({
    required this.file,
    required this.repositoryId,
    super.isLoading = false,
    super.error,
  }) : super(fileName: basename(file.name));

  @override
  List<Object?> get props => [file.name, isLoading, error];
}

@immutable
class EditMusicSheetState extends AddEditMusicSheetState {
  final Playlist playlist;
  final MusicSheet musicSheet;
  EditMusicSheetState({
    required this.playlist,
    required this.musicSheet,
    super.isLoading = false,
    super.error,
  }) : super(fileName: musicSheet.fileName);

  @override
  List<Object?> get props => [fileName, musicSheet, isLoading, error];
}

@immutable
class AddMusicSheetToPlaylistState extends AddEditMusicSheetState {
  final MusicSheet musicSheet;
  AddMusicSheetToPlaylistState({
    required this.musicSheet,
    super.isLoading = false,
    super.error,
  }) : super(fileName: musicSheet.fileName);

  @override
  List<Object?> get props => [fileName, musicSheet, isLoading, error];
}
