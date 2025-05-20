import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:organista/services/auth/auth_error.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:equatable/equatable.dart';
import 'package:organista/services/auth/auth_service.dart';
import 'package:organista/services/auth/auth_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.firebaseFirestoreRepository,
    required this.firebaseStorageRepository,
  }) : super(const AuthStateLoggedOut(isLoading: false)) {
    on<AuthEventGoToRegistration>(_authEventGoToRegistration);
    on<AuthEventLogIn>(_authEventLogIn);
    on<AuthEventGoToLogin>(_authEventGoToLogin);
    on<AuthEventRegister>(_authEventRegister);
    on<AuthEventInitialize>(_authEventInitialize);
    on<AuthEventLogOut>(_authEventLogOut);
    on<AuthEventDeleteAccount>(_authEventDeleteAccount);
    on<AuthEventForgotPassword>(_authEventForgotPassword);
  }

  final FirebaseFirestoreRepository firebaseFirestoreRepository;
  final FirebaseStorageRepository firebaseStorageRepository;

  void _authEventDeleteAccount(event, emit) async {
    final user = state.user;
    // log the user out if we don't have a current user
    if (user == null) {
      emit(const AuthStateLoggedOut(isLoading: false));
      return;
    }
    // start loading
    emit(
      AuthStateLoggedIn(
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
        const AuthStateLoggedOut(
          isLoading: false,
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AuthStateLoggedIn(
          isLoading: false,
          user: user,
          authError: AuthError.from(e),
        ),
      );
    } on FirebaseException {
      // we might not be able to delete the folder
      // log the user out
      emit(
        const AuthStateLoggedOut(
          isLoading: false,
        ),
      );
    }
  }

  void _authEventLogOut(event, emit) async {
    // start loading
    emit(
      const AuthStateLoggedOut(
        isLoading: true,
      ),
    );
    // log the user out
    await AuthService.firebase().logOut();
    // log the user out in the UI as well
    emit(
      const AuthStateLoggedOut(
        isLoading: false,
      ),
    );
  }

  void _authEventInitialize(event, emit) async {
    final user = AuthService.firebase().currentUser;
    if (user == null) {
      emit(
        const AuthStateLoggedOut(
          isLoading: false,
        ),
      );
    } else {
      emit(AuthStateLoggedIn(
        isLoading: false,
        user: user,
      ));
    }
  }

  void _authEventRegister(event, emit) async {
    // start loading
    emit(
      const AuthStateIsInRegistrationView(
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
        AuthStateLoggedIn(isLoading: false, user: authUser),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AuthStateIsInRegistrationView(
          isLoading: false,
          authError: AuthError.from(e),
        ),
      );
    }
  }

  void _authEventGoToLogin(event, emit) {
    emit(
      const AuthStateLoggedOut(
        isLoading: false,
      ),
    );
  }

  void _authEventLogIn(event, emit) async {
    emit(
      const AuthStateLoggedOut(
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
        AuthStateLoggedIn(
          isLoading: false,
          user: user,
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AuthStateLoggedOut(
          isLoading: false,
          authError: AuthError.from(e),
        ),
      );
    }
  }

  void _authEventGoToRegistration(event, emit) {
    emit(
      const AuthStateIsInRegistrationView(
        isLoading: false,
      ),
    );
  }

  void _authEventForgotPassword(event, emit) async {
    emit(
      const AuthStateLoggedOut(
        isLoading: true,
      ),
    );
    try {
      final resetSuccess = await AuthService.firebase().sendPasswordResetEmail(email: event.email);
      emit(
        AuthStateLoggedOut(
          isLoading: false,
          passwordResetSent: resetSuccess,
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AuthStateLoggedOut(
          isLoading: false,
          authError: AuthError.from(e),
        ),
      );
    }
  }
}
