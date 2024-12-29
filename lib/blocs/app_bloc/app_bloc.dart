import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:organista/auth/auth_error.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:organista/blocs/app_bloc/app_event.dart';
import 'package:organista/blocs/app_bloc/app_state.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/utils/firebase_utils.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppStateLoggedOut(isLoading: false)) {
    on<AppEventGoToRegistration>(_appEventGoToRegistration);
    on<AppEventLogIn>(_appEventLogIn);
    on<AppEventGoToLogin>(_appEventGoToLogin);
    on<AppEventRegister>(_appEventRegister);
    on<AppEventInitialize>(_appEventInitialize);
    on<AppEventLogOut>(_appEventLogOut);
    on<AppEventDeleteAccount>(_appEventDeleteAccount);
    on<AppEventUploadImage>(_appEventUploadImage);
    on<AppEventDeleteMusicSheet>(_appEventDeleteMusicSheet);
  }

  void _appEventDeleteMusicSheet(event, emit) async {
    final user = state.user;
    // log user out if we don't have an actual user in app state
    if (user == null) {
      emit(
        const AppStateLoggedOut(
          isLoading: false,
        ),
      );
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
    Reference imageToDelete = FirebaseStorage.instance.ref(musicSheetToDelete.originalFileStorageId);
    await removeImage(file: imageToDelete);
    await removeMusicSheet(musicSheet: musicSheetToDelete);
    // after remove is complete, grab the latest file references
    await _handleLogInWithImages(user, emit);
  }

  void _appEventUploadImage(event, emit) async {
    final user = state.user;
    // log user out if we don't have an actual user in app state
    if (user == null) {
      emit(
        const AppStateLoggedOut(
          isLoading: false,
        ),
      );
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
    await uploadImage(
      file: file,
      userId: user.uid,
      fileName: fileName,
    );
    await _handleLogInWithImages(user, emit);
  }

  void _appEventDeleteAccount(event, emit) async {
    final user = FirebaseAuth.instance.currentUser;
    // log the user out if we don't have a current user
    if (user == null) {
      emit(
        const AppStateLoggedOut(
          isLoading: false,
        ),
      );
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
    // delete the user folder
    try {
      // delete user folder
      final folderContents = await FirebaseStorage.instance.ref(user.uid).listAll();
      for (final item in folderContents.items) {
        await item.delete().catchError((_) {}); // maybe handle the error?
      }
      // delete the folder itself
      await FirebaseStorage.instance.ref(user.uid).delete().catchError((_) {});

      // delete the user
      await user.delete();
      // log the user out
      await FirebaseAuth.instance.signOut();
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
    await FirebaseAuth.instance.signOut();
    // log the user out in the UI as well
    emit(
      const AppStateLoggedOut(
        isLoading: false,
      ),
    );
  }

  void _appEventInitialize(event, emit) async {
    // get the current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(
        const AppStateLoggedOut(
          isLoading: false,
        ),
      );
    } else {
      await _handleLogInWithImages(user, emit);
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
      final credentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // get images for user
      final user = userCredential.user!;
      await _handleLogInWithImages(user, emit);
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

  Future<Iterable<MusicSheet>> _getMusicSheets(String userId) => FirebaseFirestore.instance
      .collection(userId)
      .orderBy(MusicSheetKey.sequenceId, descending: false)
      .get()
      .then((snapshots) => snapshots.docs.where((doc) => !doc.metadata.hasPendingWrites).map((doc) => MusicSheet(
            musicSheetId: doc.id,
            json: doc.data(),
          )));

  Future<void> _handleLogInWithImages(User user, Emitter<AppState> emit) async {
    final musicSheets = await _getMusicSheets(user.uid);
    emit(
      AppStateLoggedIn(
        isLoading: false,
        user: user,
        musicSheets: musicSheets,
      ),
    );
  }
}
