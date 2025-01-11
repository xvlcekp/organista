part of 'add_music_sheet_cubit.dart';

final class AddMusicSheetState extends Equatable {
  const AddMusicSheetState({
    required this.musicSheetId,
    required this.file,
    required this.fileName,
    required this.isValid,
    required this.errorMessage,
  });

  final String? musicSheetId;
  final Uint8List? file;
  final String fileName;
  final bool isValid;
  final String? errorMessage;

  @override
  List<Object?> get props => [musicSheetId, file, fileName, isValid, errorMessage];

  const AddMusicSheetState.init()
      : musicSheetId = '',
        file = null,
        fileName = '',
        isValid = false,
        errorMessage = null;

  AddMusicSheetState copyWith({
    String? musicSheetId,
    Uint8List? file,
    String? fileName,
    bool? isValid,
    String? errorMessage,
  }) {
    return AddMusicSheetState(
      musicSheetId: musicSheetId ?? this.musicSheetId,
      file: file ?? this.file,
      fileName: fileName ?? this.fileName,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
