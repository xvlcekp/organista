import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'add_music_sheet_state.dart';

class AddMusicSheetCubit extends Cubit<AddMusicSheetState> {
  AddMusicSheetCubit() : super(const AddMusicSheetState.init());

  void resetState() {
    emit(const AddMusicSheetState.init());
  }

  void newMusicSheet({
    required String fileName,
    required Uint8List file,
  }) async {
    emit(state.copyWith(
      fileName: fileName,
      file: file,
    ));
  }
}
