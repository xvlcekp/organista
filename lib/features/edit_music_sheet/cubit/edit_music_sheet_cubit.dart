import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';

part 'edit_music_sheet_state.dart';

class EditMusicSheetCubit extends Cubit<EditMusicSheetState> {
  EditMusicSheetCubit() : super(const EditMusicSheetState.init());

  void resetState() {
    emit(const EditMusicSheetState.init());
  }

  void editMusicSheet({required MusicSheet musicSheet}) {
    emit(state.copyWith(
      musicSheet: musicSheet,
    ));
  }
}
