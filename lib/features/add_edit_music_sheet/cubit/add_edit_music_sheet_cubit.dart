import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:meta/meta.dart' show immutable;
import 'package:organista/features/add_edit_music_sheet/error/add_edit_music_sheet_error.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:path/path.dart';

part 'add_edit_music_sheet_state.dart';

class AddEditMusicSheetCubit extends Cubit<AddEditMusicSheetState> {
  final FirebaseFirestoreRepository _firebaseFirestoreRepository;
  final FirebaseStorageRepository _firebaseStorageRepository;

  AddEditMusicSheetCubit({
    required FirebaseFirestoreRepository firebaseFirestoreRepository,
    required FirebaseStorageRepository firebaseStorageRepository,
  }) : _firebaseFirestoreRepository = firebaseFirestoreRepository,
       _firebaseStorageRepository = firebaseStorageRepository,
       super(const InitMusicSheetState());

  void resetState() {
    emit(const InitMusicSheetState());
  }

  void uploadMusicSheet({
    required MusicSheetFile file,
    required String repositoryId,
  }) {
    emit(
      UploadMusicSheetState(
        file: file,
        repositoryId: repositoryId,
      ),
    );
  }

  void editMusicSheetInPlaylist({required Playlist playlist, required MusicSheet musicSheet}) {
    emit(
      EditMusicSheetState(
        playlist: playlist,
        musicSheet: musicSheet,
      ),
    );
  }

  void addMusicSheetToPlaylist({required MusicSheet musicSheet}) {
    emit(
      AddMusicSheetToPlaylistState(
        musicSheet: musicSheet,
      ),
    );
  }

  Future<void> uploadNewMusicSheet({
    required AuthUser user,
    required MusicSheetFile file,
    required String fileName,
    required String repositoryId,
  }) async {
    if (isClosed) return;

    emit(
      UploadMusicSheetState(
        file: file,
        repositoryId: repositoryId,
        isLoading: true,
      ),
    );

    final Reference? reference = await _firebaseStorageRepository.uploadFile(
      file: file,
      bucket: user.id,
    );

    final success =
        reference != null &&
        await _firebaseFirestoreRepository.uploadMusicSheetRecord(
          reference: reference,
          userId: user.id,
          fileName: fileName,
          mediaType: file.mediaType,
          repositoryId: repositoryId,
        );

    if (!isClosed) {
      if (success) {
        emit(
          UploadMusicSheetState(
            file: file,
            repositoryId: repositoryId,
            isLoading: false,
          ),
        );
      } else {
        emit(
          UploadMusicSheetState(
            file: file,
            repositoryId: repositoryId,
            isLoading: false,
            error: const UploadMusicSheetRecordFailedError(),
          ),
        );
      }
    }
  }

  void renameMusicSheetInPlaylist({
    required Playlist playlist,
    required MusicSheet musicSheet,
    required String fileName,
  }) {
    if (isClosed) return;

    emit(
      EditMusicSheetState(
        musicSheet: musicSheet,
        playlist: playlist,
        isLoading: true,
      ),
    );
    final success = _firebaseFirestoreRepository.renameMusicSheetInPlaylist(
      musicSheet: musicSheet,
      fileName: fileName,
      playlist: playlist,
    );

    if (!isClosed) {
      if (success) {
        emit(
          EditMusicSheetState(
            musicSheet: musicSheet,
            playlist: playlist,
            isLoading: false,
          ),
        );
      } else {
        emit(
          EditMusicSheetState(
            musicSheet: musicSheet,
            playlist: playlist,
            isLoading: false,
            error: const RenameMusicSheetFailedError(),
          ),
        );
      }
    }
  }
}
