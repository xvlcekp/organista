part of 'add_music_sheet_cubit.dart';

final class AddMusicSheetState extends Equatable {
  const AddMusicSheetState({
    required this.fileName,
    required this.file,
    required this.isValid,
    required this.errorMessage,
  });

  final String? fileName;
  final Uint8List? file;
  final bool isValid;
  final String? errorMessage;

  @override
  List<Object?> get props => [fileName, file, isValid, errorMessage];

  const AddMusicSheetState.init()
      : fileName = '',
        file = null,
        isValid = false,
        errorMessage = null;

  AddMusicSheetState copyWith({
    String? fileName,
    Uint8List? file,
    bool? isValid,
    String? errorMessage,
  }) {
    return AddMusicSheetState(
      fileName: fileName ?? this.fileName,
      file: file ?? this.file,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
