import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';

part 'add_edit_music_sheet_state.dart';

class AddEditMusicSheetCubit extends Cubit<AddEditMusicSheetState> {
  AddEditMusicSheetCubit() : super(const InitMusicSheetState());

  void resetState() {
    emit(const InitMusicSheetState());
  }

  void uploadMusicSheet({required String fileName, required Uint8List file, required MediaType mediaType}) {
    emit(UploadMusicSheetState(fileName: fileName, file: file, mediaType: mediaType));
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
