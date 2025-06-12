import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseException, FirebaseAuthException;
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/services/auth/auth_error.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:equatable/equatable.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/services/auth/auth_provider.dart';
import 'package:organista/services/stream_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    on<AuthEventSignInWithGoogle>(_authEventSignInWithGoogle);
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

  /// Helper method to rollback Firebase Auth user creation with proper logging
  Future<void> _rollbackAuthUser(String context) async {
    logger.e('Failed to create user data in Firestore during $context');
    try {
      await authProvider.deleteUser();
      logger.i('Successfully rolled back Firebase Auth user creation during $context');
    } catch (deleteError) {
      logger.e('Failed to rollback Firebase Auth user during $context: $deleteError');
      // Continue execution - rollback failure shouldn't prevent showing original error
    }
  }

  /// Helper method to check if an error indicates user already exists
  bool _isUserAlreadyExistsError(Object error) {
    final errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('already exists') || errorMessage.contains('document already exists') || errorMessage.contains('permission-denied');
  }

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
      // Cancel all Firebase streams first to prevent permission errors
      await StreamManager.instance.cancelAllStreams();

      // First, sign out from Google Sign-In to prevent state issues
      try {
        await GoogleSignIn().signOut();
      } catch (e) {
        // Ignore if Google Sign-In fails - user might not be signed in via Google
        logger.i('Google Sign-Out during account deletion: $e');
      }

      // Delete user data from Firestore and Storage
      await firebaseFirestoreRepository.deleteUser(userId: user.id);
      await firebaseStorageRepository.deleteFolder(user.id);

      // Delete the Firebase user account
      await authProvider.deleteUser();

      // Emit logged out state immediately after successful deletion
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
      // we might not be able to delete the folder, but user is deleted
      // log the user out anyway
      emit(
        const AuthStateLoggedOut(
          isLoading: false,
        ),
      );
    } catch (e) {
      // Handle any other errors
      logger.e('Error during account deletion: $e');
      emit(
        AuthStateLoggedIn(
          isLoading: false,
          user: user,
          authError: const AuthGenericException(),
        ),
      );
    }
  }

  void _authEventLogOut(event, emit) async {
    // start loading
    emit(
      const AuthStateLoggedOut(isLoading: true),
    );

    // Cancel all Firebase streams first to prevent permission errors
    await StreamManager.instance.cancelAllStreams();

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

      try {
        await firebaseFirestoreRepository.uploadNewUser(
          user: authUser,
        );
        await firebaseFirestoreRepository.createUserRepository(
          user: authUser,
        );
      } catch (e) {
        // Firestore operations failed - rollback the Firebase Auth user
        await _rollbackAuthUser('registration');
        rethrow; // Re-throw the original error
      }

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
    } catch (e) {
      // Handle any non-FirebaseAuth errors (including Firestore rollback errors)
      emit(
        AuthStateIsInRegistrationView(
          isLoading: false,
          authError: const AuthGenericException(),
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

  void _authEventSignInWithGoogle(event, emit) async {
    emit(
      const AuthStateLoggedOut(isLoading: true),
    );
    try {
      final authUser = await authProvider.signInWithGoogle();

      // we need to manually check if user/repository already exists in DB
      try {
        await firebaseFirestoreRepository.uploadNewUser(
          user: authUser,
        );
        await firebaseFirestoreRepository.createUserRepository(
          user: authUser,
        );
      } catch (e) {
        // Check if this is a "user already exists" error or a real failure
        if (_isUserAlreadyExistsError(e)) {
          // User already exists, this is fine - continue with login
          logger.i('User already exists in Firestore, continuing with Google Sign-In: $e');
        } else {
          // This is a real failure - rollback the Firebase Auth user
          await _rollbackAuthUser('Google Sign-In');
          rethrow; // Re-throw the original error
        }
      }

      emit(
        AuthStateLoggedIn(
          isLoading: false,
          user: authUser,
        ),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AuthStateLoggedOut(
          isLoading: false,
          authError: AuthError.from(e),
        ),
      );
    } catch (e) {
      emit(
        const AuthStateLoggedOut(
          isLoading: false,
          authError: AuthGenericException(),
        ),
      );
    }
  }
}
