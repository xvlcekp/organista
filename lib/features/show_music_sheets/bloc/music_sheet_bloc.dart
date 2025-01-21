import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show Uint8List, immutable;
import 'package:equatable/equatable.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';

part 'music_sheet_event.dart';
part 'music_sheet_state.dart';

class MusicSheetBloc extends Bloc<MusicSheetEvent, MusicSheetState> {
  MusicSheetBloc({
    required this.firebaseFirestoreRepositary,
    required this.firebaseStorageRepository,
  }) : super(const MusicSheetsInitState()) {
    on<UploadImageMusicSheetEvent>(_uploadImageMusicSheetEvent);
    on<DeleteMusicSheetEvent>(_deleteMusicSheetEvent);
    on<ReorderMusicSheetEvent>(_reorderMusicSheetEvent);
    on<RenameMusicSheetEvent>(_renameMusicSheetEvent);
    on<InitMusicSheetEvent>(_initMusicSheetEvent);
  }

  final FirebaseFirestoreRepository firebaseFirestoreRepositary;
  final FirebaseStorageRepository firebaseStorageRepository;

  void _uploadImageMusicSheetEvent(event, emit) async {
    // start the loading process
    emit(
      MusicSheetsLoadedState(
        isLoading: true,
        musicSheets: state.musicSheets,
      ),
    );
    // upload the file
    final file = event.file;
    final fileName = event.fileName;
    final user = event.user;
    try {
      final Reference? reference = await firebaseStorageRepository.uploadImage(
        file: file,
        userId: user.uid,
      );
      if (reference != null) {
        await firebaseFirestoreRepositary.uploadMusicSheetRecord(
          reference: reference,
          userId: user.uid,
          fileName: fileName,
          totalMusicSheets: state.musicSheets.length,
        );
        emit(MusicSheetsLoadedState(
          isLoading: false,
          musicSheets: state.musicSheets,
        ));
      } else {
        throw Exception('Failed to upload image, not uploading MusicSheet record to Firestore');
      }
    } catch (e) {
      CustomLogger.instance.e('Failed to upload image: $e');
      emit(
        MusicSheetsLoadedState(
          isLoading: false,
          musicSheets: state.musicSheets,
        ),
      );
    }
  }

  void _deleteMusicSheetEvent(event, emit) async {
    emit(
      MusicSheetsLoadedState(
        isLoading: true,
        musicSheets: state.musicSheets,
      ),
    );
    // remove the file
    final MusicSheet musicSheetToDelete = event.musicSheet;
    Reference imageToDelete = firebaseStorageRepository.getReference(musicSheetToDelete.originalFileStorageId);
    await firebaseFirestoreRepositary.removeImage(file: imageToDelete);
    await firebaseFirestoreRepositary.removeMusicSheet(musicSheet: musicSheetToDelete);
  }

  void _reorderMusicSheetEvent(event, emit) async {
    emit(MusicSheetsLoadedState(
      isLoading: false,
      musicSheets: event.musicSheets,
    ));
    firebaseFirestoreRepositary.musicSheetReorder(musicSheets: event.musicSheets);
  }

  void _renameMusicSheetEvent(event, emit) async {
    final musicSheet = event.musicSheet;
    final fileName = event.fileName;
    firebaseFirestoreRepositary.editMusicSheet(
      musicSheet: musicSheet,
      fileName: fileName,
    );
  }

  void _initMusicSheetEvent(event, emit) async {
    final User user = event.user;
    await emit.forEach<Iterable<MusicSheet>>(
      firebaseFirestoreRepositary.getMusicSheetsStream(user.uid),
      onData: (musicSheets) => MusicSheetsLoadedState(
        isLoading: false,
        musicSheets: musicSheets,
      ),
      onError: (_, __) => const MusicSheetsErrorState(),
    );
  }
}
