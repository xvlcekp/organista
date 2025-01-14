part of 'edit_music_sheet_cubit.dart';

final class EditMusicSheetState extends Equatable {
  const EditMusicSheetState({
    required this.musicSheet,
  });

  final MusicSheet? musicSheet;

  @override
  List<Object?> get props => [musicSheet];

  const EditMusicSheetState.init() : musicSheet = null;

  EditMusicSheetState copyWith({
    MusicSheet? musicSheet,
  }) {
    return EditMusicSheetState(
      musicSheet: musicSheet ?? this.musicSheet,
    );
  }
}
