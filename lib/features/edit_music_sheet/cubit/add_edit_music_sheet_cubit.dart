import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';

part 'add_edit_music_sheet_state.dart';

class AddEditMusicSheetCubit extends Cubit<AddEditMusicSheetState> {
  AddEditMusicSheetCubit() : super(const InitMusicSheetState());

  void resetState() {
    emit(const InitMusicSheetState());
  }

  void addMusicSheet({required String fileName, required Uint8List file}) {
    emit(AddMusicSheetState(
      fileName: fileName,
      file: file,
    ));
  }

  void editMusicSheet({required String fileName, required MusicSheet musicSheet}) {
    emit(EditMusicSheetState(
      fileName: fileName,
      musicSheet: musicSheet,
    ));
  }
}
