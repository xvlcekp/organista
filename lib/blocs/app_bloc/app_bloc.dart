import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:organista/services/auth/auth_error.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:equatable/equatable.dart';
import 'package:organista/services/auth/auth_service.dart';
import 'package:organista/services/auth/auth_user.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required this.firebaseFirestoreRepository,
    required this.firebaseStorageRepository,
  }) : super(const AppStateLoggedOut(isLoading: false)) {
    on<AppEventGoToRegistration>(_appEventGoToRegistration);
    on<AppEventLogIn>(_appEventLogIn);
    on<AppEventGoToLogin>(_appEventGoToLogin);
    on<AppEventRegister>(_appEventRegister);
    on<AppEventInitialize>(_appEventInitialize);
    on<AppEventLogOut>(_appEventLogOut);
    on<AppEventDeleteAccount>(_appEventDeleteAccount);
    on<AppEventForgotPassword>(_appEventForgotPassword);
  }

  final FirebaseFirestoreRepository firebaseFirestoreRepository;
  final FirebaseStorageRepository firebaseStorageRepository;

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
      ),
    );
    try {
      await firebaseFirestoreRepository.deleteUser(userId: user.id);
      await firebaseStorageRepository.deleteFolder(user.id);
      // delete the user
      await AuthService.firebase().deleteUser();
      // log the user out
      await AuthService.firebase().logOut();
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
    await AuthService.firebase().logOut();
    // log the user out in the UI as well
    emit(
      const AppStateLoggedOut(
        isLoading: false,
      ),
    );
  }

  void _appEventInitialize(event, emit) async {
    final user = AuthService.firebase().currentUser;
    if (user == null) {
      emit(
        const AppStateLoggedOut(
          isLoading: false,
        ),
      );
    } else {
      emit(AppStateLoggedIn(
        isLoading: false,
        user: user,
      ));
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
      final authUser = await AuthService.firebase().createUser(
        email: email,
        password: password,
      );
      await firebaseFirestoreRepository.uploadNewUser(
        user: authUser,
      );
      await firebaseFirestoreRepository.createUserRepository(
        user: authUser,
      );
      emit(
        AppStateLoggedIn(isLoading: false, user: authUser),
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
      final authUser = await AuthService.firebase().logIn(
        email: email,
        password: password,
      );
      final user = authUser;
      emit(
        AppStateLoggedIn(
          isLoading: false,
          user: user,
        ),
      );
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

  void _appEventForgotPassword(event, emit) async {
    emit(
      const AppStateLoggedOut(
        isLoading: true,
      ),
    );
    try {
      final resetSuccess = await AuthService.firebase().sendPasswordResetEmail(email: event.email);
      emit(
        AppStateLoggedOut(
          isLoading: false,
          passwordResetSent: resetSuccess,
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AppStateLoggedOut(
          isLoading: false,
          authError: AuthError.from(e),
        ),
      );
    }
  }
}
