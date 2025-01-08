part of 'add_music_sheet_cubit.dart';

final class AddMusicSheetState extends Equatable {
  const AddMusicSheetState({
    this.fileName = '',
    this.isValid = false,
    this.errorMessage,
    this.file,
  });

  final String fileName;
  final bool isValid;
  final String? errorMessage;
  final Uint8List? file;

  @override
  List<Object?> get props => [fileName, isValid, errorMessage, file];

  AddMusicSheetState copyWith({
    String? fileName,
    bool? isValid,
    String? errorMessage,
    Uint8List? file,
  }) {
    return AddMusicSheetState(
      fileName: fileName ?? this.fileName,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
      file: file ?? this.file,
    );
  }
}
