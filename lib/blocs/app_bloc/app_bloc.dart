import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:organista/auth/auth_error.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/repositories/firebase_auth_repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:equatable/equatable.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required this.firebaseAuthRepository,
    required this.firebaseFirestoreRepositary,
    required this.firebaseStorageRepository,
  }) : super(const AppStateLoggedOut(isLoading: false)) {
    on<AppEventGoToRegistration>(_appEventGoToRegistration);
    on<AppEventLogIn>(_appEventLogIn);
    on<AppEventGoToLogin>(_appEventGoToLogin);
    on<AppEventRegister>(_appEventRegister);
    on<AppEventInitialize>(_appEventInitialize);
    on<AppEventLogOut>(_appEventLogOut);
    on<AppEventDeleteAccount>(_appEventDeleteAccount);
    on<AppEventUploadImage>(_appEventUploadImage);
    on<AppEventDeleteMusicSheet>(_appEventDeleteMusicSheet);
    on<AppEventReorderMusicSheet>(_appEventReorderMusicSheet);
  }

  final FirebaseAuthRepository firebaseAuthRepository;
  final FirebaseFirestoreRepository firebaseFirestoreRepositary;
  final FirebaseStorageRepository firebaseStorageRepository;

  void _appEventReorderMusicSheet(event, emit) async {
    emit(AppStateLoggedIn(
      isLoading: false,
      user: state.user!,
      musicSheets: event.musicSheets,
    ));
    firebaseFirestoreRepositary.musicSheetReorder(musicSheets: event.musicSheets);
  }

  _registerMusicSheetsSubscription(User user, emit) async {
    await emit.forEach<Iterable<MusicSheet>>(
      firebaseFirestoreRepositary.getMusicSheetsStream(user.uid),
      onData: (musicSheets) => AppStateLoggedIn(
        isLoading: false,
        user: user,
        musicSheets: musicSheets,
      ),
      onError: (_, __) => const AppStateLoggedOut(
        isLoading: false,
      ),
    );
  }

  void _appEventDeleteMusicSheet(event, emit) async {
    final user = state.user;
    // log user out if we don't have an actual user in app state
    if (user == null) {
      emit(const AppStateLoggedOut(isLoading: false));
      return;
    }
    // start the loading process
    emit(
      AppStateLoggedIn(
        isLoading: true,
        user: user,
        musicSheets: state.musicSheets ?? [],
      ),
    );
    // remove the file
    final MusicSheet musicSheetToDelete = event.musicSheetToDelete;
    Reference imageToDelete = firebaseStorageRepository.getReference(musicSheetToDelete.originalFileStorageId);
    await firebaseFirestoreRepositary.removeImage(file: imageToDelete);
    await firebaseFirestoreRepositary.removeMusicSheet(musicSheet: musicSheetToDelete);
  }

  void _appEventUploadImage(event, emit) async {
    final user = state.user;
    // log user out if we don't have an actual user in app state
    if (user == null) {
      emit(const AppStateLoggedOut(isLoading: false));
      return;
    }
    // start the loading process
    emit(
      AppStateLoggedIn(
        isLoading: true,
        user: user,
        musicSheets: state.musicSheets ?? [],
      ),
    );
    // upload the file
    final file = event.file;
    final fileName = event.fileName;
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
          totalMusicSheets: state.musicSheets?.length ?? 0,
        );
        emit(AppStateLoggedIn(
          isLoading: false,
          user: user,
          musicSheets: state.musicSheets ?? [],
        ));
      } else {
        throw Exception('Failed to upload image, not uploading MusicSheet record to Firestore');
      }
    } catch (e) {
      CustomLogger.instance.e('Failed to upload image: $e');
      // TODO: handle the error
      // emit(
      //   AppStateLoggedIn(
      //     isLoading: false,
      //     user: user,
      //     musicSheets: state.musicSheets ?? [],
      //     authError: AuthError.from(e),
      //   ),
      // );
    }
  }

  void _appEventDeleteAccount(event, emit) async {
    final user = state.user;
    // log the user out if we don't have a current user
    if (user == null) {
      emit(const AppStateLoggedOut(isLoading: false));
      return;
    }
    // start loading
    emit(
      AppStateLoggedIn(
        isLoading: true,
        user: user,
        musicSheets: state.musicSheets ?? [],
      ),
    );
    try {
      await firebaseStorageRepository.deleteFolder(user.uid);
      // delete the user
      await user.delete();
      // log the user out
      await firebaseAuthRepository.signOut();
      // log the user out in the UI as well
      emit(
        const AppStateLoggedOut(
          isLoading: false,
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AppStateLoggedIn(
          isLoading: false,
          user: user,
          musicSheets: state.musicSheets ?? [],
          authError: AuthError.from(e),
        ),
      );
    } on FirebaseException {
      // we might not be able to delete the folder
      // log the user out
      emit(
        const AppStateLoggedOut(
          isLoading: false,
        ),
      );
    }
  }

  void _appEventLogOut(event, emit) async {
    // start loading
    emit(
      const AppStateLoggedOut(
        isLoading: true,
      ),
    );
    // log the user out
    await firebaseAuthRepository.signOut();
    // log the user out in the UI as well
    emit(
      const AppStateLoggedOut(
        isLoading: false,
      ),
    );
  }

  void _appEventInitialize(event, emit) async {
    final user = firebaseAuthRepository.getCurrentUser();
    if (user == null) {
      emit(
        const AppStateLoggedOut(
          isLoading: false,
        ),
      );
    } else {
      await _registerMusicSheetsSubscription(user, emit);
    }
  }

  void _appEventRegister(event, emit) async {
    // start loading
    emit(
      const AppStateIsInRegistrationView(
        isLoading: true,
      ),
    );
    final email = event.email;
    final password = event.password;
    try {
      // create the user
      final credentials = await firebaseAuthRepository.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      emit(
        AppStateLoggedIn(isLoading: false, user: credentials.user!, musicSheets: const []),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AppStateIsInRegistrationView(
          isLoading: false,
          authError: AuthError.from(e),
        ),
      );
    }
  }

  void _appEventGoToLogin(event, emit) {
    emit(
      const AppStateLoggedOut(
        isLoading: false,
      ),
    );
  }

  void _appEventLogIn(event, emit) async {
    emit(
      const AppStateLoggedOut(
        isLoading: true,
      ),
    );
    // log the user in
    try {
      final email = event.email;
      final password = event.password;
      final userCredential = await firebaseAuthRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // get images for user
      final user = userCredential.user!;
      await _registerMusicSheetsSubscription(user, emit);
    } on FirebaseAuthException catch (e) {
      emit(
        AppStateLoggedOut(
          isLoading: false,
          authError: AuthError.from(e),
        ),
      );
    }
  }

  void _appEventGoToRegistration(event, emit) {
    emit(
      const AppStateIsInRegistrationView(
        isLoading: false,
      ),
    );
  }
}
