import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:organista/auth/auth_error.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:organista/blocs/app_bloc/app_event.dart';
import 'package:organista/blocs/app_bloc/app_state.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/utils/firebase_utils.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc()
      : super(
          const AppStateLoggedOut(
            isLoading: false,
          ),
        ) {
    on<AppEventGoToRegistration>((event, emit) {
      emit(
        const AppStateIsInRegistrationView(
          isLoading: false,
        ),
      );
    });
    on<AppEventLogIn>(
      (event, emit) async {
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
      },
    );
    on<AppEventGoToLogin>(
      (event, emit) {
        emit(
          const AppStateLoggedOut(
            isLoading: false,
          ),
        );
      },
    );
    on<AppEventRegister>(
      (event, emit) async {
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
            AppStateLoggedIn(isLoading: false, user: credentials.user!, images: const [], imagesData: const []),
          );
        } on FirebaseAuthException catch (e) {
          emit(
            AppStateIsInRegistrationView(
              isLoading: false,
              authError: AuthError.from(e),
            ),
          );
        }
      },
    );
    on<AppEventInitialize>(
      (event, emit) async {
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
      },
    );
    // log out event
    on<AppEventLogOut>(
      (event, emit) async {
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
      },
    );
    // handle account deletion
    on<AppEventDeleteAccount>(
      (event, emit) async {
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
            images: state.images ?? [],
            imagesData: state.imagesData ?? [],
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
              images: state.images ?? [],
              imagesData: state.imagesData ?? [],
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
      },
    );

    // handle uploading images
    on<AppEventUploadImage>(
      (event, emit) async {
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
            images: state.images ?? [],
            imagesData: state.imagesData ?? [],
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
      },
    );

    // handle uploading images
    on<AppEventDeleteImage>(
      (event, emit) async {
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
            images: state.images ?? [],
            imagesData: state.imagesData ?? [],
          ),
        );
        // remove the file
        final MusicSheet musicSheetToDelete = event.musicSheetToDelete;
        Reference imageToDelete = FirebaseStorage.instance.ref(musicSheetToDelete.originalFileStorageId);
        await removeImage(file: imageToDelete);
        await removeMusicSheet(musicSheet: musicSheetToDelete);
        // after remove is complete, grab the latest file references
        await _handleLogInWithImages(user, emit);
      },
    );
  }

  Future<Iterable<Reference>> _getImages(String userId) => FirebaseStorage.instance.ref(userId).list().then((listResult) => listResult.items);

  Future<Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>> _getImageData(String userId) => FirebaseFirestore.instance.collection(userId).get().then((onValue) => onValue.docs);

  Future<void> _handleLogInWithImages(User user, Emitter<AppState> emit) async {
    final images = await _getImages(user.uid);
    final imagesData = await _getImageData(user.uid);
    emit(
      AppStateLoggedIn(
        isLoading: false,
        user: user,
        images: images,
        imagesData: imagesData,
      ),
    );
  }
}
