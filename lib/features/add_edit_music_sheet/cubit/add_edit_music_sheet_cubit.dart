import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:path/path.dart';

part 'add_edit_music_sheet_state.dart';

class AddEditMusicSheetCubit extends Cubit<AddEditMusicSheetState> {
  AddEditMusicSheetCubit() : super(const InitMusicSheetState());

  void resetState() {
    emit(const InitMusicSheetState());
  }

  void uploadMusicSheet({required PlatformFile file}) {
    emit(UploadMusicSheetState(file: file));
  }

  void editMusicSheetInPlaylist({required Playlist playlist, required MusicSheet musicSheet}) {
    emit(EditMusicSheetState(
      playlist: playlist,
      musicSheet: musicSheet,
    ));
  }

  void addMusicSheetToPlaylist({required MusicSheet musicSheet}) {
    emit(AddMusicSheetToPlaylistState(
      musicSheet: musicSheet,
    ));
  }
}
