import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'add_music_sheet_state.dart';

class AddMusicSheetCubit extends Cubit<AddMusicSheetState> {
  AddMusicSheetCubit() : super(const AddMusicSheetState());

  void resetState() {
    emit(const AddMusicSheetState());
  }

  void fileNameChanged(String value) {
    final fileName = value;
    emit(
      state.copyWith(
        fileName: fileName,
      ),
    );
  }

  void imageUploaded(Uint8List image) {
    emit(state.copyWith(file: image));
  }

  void uploadImage(Uint8List image, String fileName) async {
    fileNameChanged(fileName);
    imageUploaded(image);
  }
}
