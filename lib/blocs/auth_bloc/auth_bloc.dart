import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseException, FirebaseAuthException;
import 'package:organista/services/auth/auth_error.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:equatable/equatable.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/services/auth/auth_provider.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.authProvider,
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

  final AuthProvider authProvider;
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
      await authProvider.deleteUser();
      // log the user out
      await authProvider.logOut();
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
      const AuthStateLoggedOut(isLoading: true),
    );
    // log the user out
    await authProvider.logOut();
    // log the user out in the UI as well
    emit(
      const AuthStateLoggedOut(isLoading: false),
    );
  }

  void _authEventInitialize(event, emit) async {
    await authProvider.initialize();
    final user = authProvider.currentUser;
    if (user == null) {
      emit(
        const AuthStateLoggedOut(isLoading: false),
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
      final authUser = await authProvider.createUser(
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
      const AuthStateLoggedOut(isLoading: true),
    );
    // log the user in
    try {
      final email = event.email;
      final password = event.password;
      final authUser = await authProvider.logIn(
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
      final resetSuccess = await authProvider.sendPasswordResetEmail(email: event.email);
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
