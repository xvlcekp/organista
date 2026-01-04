import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseException, FirebaseAuthException;
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/services/auth/auth_error.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/services/auth/auth_provider.dart';
import 'package:organista/managers/stream_manager.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthProvider authProvider,
    required FirebaseFirestoreRepository firebaseFirestoreRepository,
    required FirebaseStorageRepository firebaseStorageRepository,
  }) : _firebaseStorageRepository = firebaseStorageRepository,
       _firebaseFirestoreRepository = firebaseFirestoreRepository,
       _authProvider = authProvider,
       super(const AuthStateLoggedOut(isLoading: false)) {
    on<AuthEventGoToRegistration>(_authEventGoToRegistration);
    on<AuthEventLogIn>(_authEventLogIn);
    on<AuthEventSignInWithGoogle>(_authEventSignInWithGoogle);
    on<AuthEventSignInWithApple>(_authEventSignInWithApple);
    on<AuthEventGoToLogin>(_authEventGoToLogin);
    on<AuthEventRegister>(_authEventRegister);
    on<AuthEventInitialize>(_authEventInitialize);
    on<AuthEventLogOut>(_authEventLogOut);
    on<AuthEventDeleteAccount>(_authEventDeleteAccount);
    on<AuthEventForgotPassword>(_authEventForgotPassword);
  }

  final AuthProvider _authProvider;
  final FirebaseFirestoreRepository _firebaseFirestoreRepository;
  final FirebaseStorageRepository _firebaseStorageRepository;

  void _authEventDeleteAccount(AuthEventDeleteAccount event, Emitter<AuthState> emit) async {
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

      if (!_ensureRecentLogin(user, emit)) {
        return;
      }

      // Delete user data from Firestore and Storage
      await _firebaseFirestoreRepository.deleteUser(userId: user.id);
      await _firebaseStorageRepository.deleteFolder(user.id);

      // Delete the Firebase user account
      await _authProvider.deleteUser();

      // Emit logged out state immediately after successful deletion
      emit(
        const AuthStateLoggedOut(
          isLoading: false,
        ),
      );

      unawaited(_updateSentryUser(null));
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
    } catch (e, stackTrace) {
      // Handle any other errors
      logger.e('Error during account deletion', error: e, stackTrace: stackTrace);
      emit(
        AuthStateLoggedIn(
          isLoading: false,
          user: user,
          authError: const AuthGenericException(),
        ),
      );
    }
  }

  void _authEventLogOut(AuthEventLogOut event, Emitter<AuthState> emit) async {
    try {
      emit(const AuthStateLoggedOut(isLoading: true));

      // Cancel all Firebase streams first to prevent permission errors
      await StreamManager.instance.cancelAllStreams();

      await _authProvider.logOut();

      unawaited(_updateSentryUser(null));

      emit(
        const AuthStateLoggedOut(isLoading: false),
      );
    } on FirebaseAuthException catch (e) {
      emit(
        AuthStateLoggedOut(
          isLoading: false,
          authError: AuthError.from(e),
        ),
      );
    } catch (e) {
      // Even if logout fails, we should clear the state
      emit(
        const AuthStateLoggedOut(
          isLoading: false,
          authError: AuthGenericException(),
        ),
      );
    }
  }

  void _authEventInitialize(AuthEventInitialize event, Emitter<AuthState> emit) async {
    try {
      await _authProvider.initialize();
      final user = _authProvider.currentUser;

      if (user == null) {
        emit(
          const AuthStateLoggedOut(isLoading: false),
        );
      } else {
        // Small delay to ensure Firebase services (like Firestore) are fully aware
        // of the auth state before any queries are triggered by the UI.
        await Future.delayed(const Duration(milliseconds: 200));

        unawaited(_updateSentryUser(user));

        emit(
          AuthStateLoggedIn(
            isLoading: false,
            user: user,
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.e('Error during auth initialization', error: e, stackTrace: stackTrace);
      emit(
        const AuthStateLoggedOut(isLoading: false),
      );
    }
  }

  void _authEventRegister(AuthEventRegister event, Emitter<AuthState> emit) async {
    emit(
      const AuthStateLoggedOut(isLoading: true),
    );
    try {
      final authUser = await _authProvider.createUser(
        email: event.email,
        password: event.password,
      );

      // Create user document in Firestore
      await _firebaseFirestoreRepository.createUserDocument(
        user: authUser,
      );

      unawaited(_updateSentryUser(authUser));

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

  void _authEventGoToLogin(AuthEventGoToLogin event, Emitter<AuthState> emit) {
    emit(
      const AuthStateLoggedOut(isLoading: false),
    );
  }

  void _authEventGoToRegistration(AuthEventGoToRegistration event, Emitter<AuthState> emit) {
    emit(
      const AuthStateIsInRegistrationView(isLoading: false),
    );
  }

  void _authEventLogIn(AuthEventLogIn event, Emitter<AuthState> emit) async {
    emit(
      const AuthStateLoggedOut(isLoading: true),
    );
    try {
      final authUser = await _authProvider.logIn(
        email: event.email,
        password: event.password,
      );
      unawaited(_updateSentryUser(authUser));

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

  void _authEventForgotPassword(AuthEventForgotPassword event, Emitter<AuthState> emit) async {
    emit(
      const AuthStateLoggedOut(isLoading: true),
    );
    try {
      final resetSuccess = await _authProvider.sendPasswordResetEmail(email: event.email);
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
          passwordResetSent: false,
        ),
      );
    } catch (e) {
      emit(
        const AuthStateLoggedOut(
          isLoading: false,
          authError: AuthGenericException(),
          passwordResetSent: false,
        ),
      );
    }
  }

  void _authEventSignInWithGoogle(AuthEventSignInWithGoogle event, Emitter<AuthState> emit) async {
    emit(
      const AuthStateLoggedOut(isLoading: true),
    );
    try {
      final authUser = await _authProvider.signInWithGoogle();

      // Create user document in Firestore if it doesn't exist
      await _firebaseFirestoreRepository.createUserDocument(
        user: authUser,
      );

      unawaited(_updateSentryUser(authUser));

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

  void _authEventSignInWithApple(
    AuthEventSignInWithApple event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      const AuthStateLoggedOut(isLoading: true),
    );
    try {
      final authUser = await _authProvider.signInWithApple();

      await _firebaseFirestoreRepository.createUserDocument(
        user: authUser,
      );

      unawaited(_updateSentryUser(authUser));

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

  Future<void> _updateSentryUser(AuthUser? user) async {
    await Sentry.configureScope((scope) {
      if (user == null) {
        scope.setUser(null);
      } else {
        scope.setUser(
          SentryUser(
            id: user.id,
            email: user.email,
          ),
        );
      }
    });
  }

  /// Prevents deleting user data without deleting user.
  /// User needs to be freshly logged in to delete it, but it is possible to delete user's data without reauthentication.
  bool _ensureRecentLogin(AuthUser user, Emitter<AuthState> emit) {
    const recentLoginMaxDuration = Duration(minutes: 5);
    final lastSignInTime = user.lastSignInTime;
    if (lastSignInTime == null || DateTime.now().difference(lastSignInTime) > recentLoginMaxDuration) {
      emit(
        AuthStateLoggedIn(
          isLoading: false,
          user: user,
          authError: const AuthErrorRequiresRecentLogin(),
        ),
      );
      return false;
    }
    return true;
  }
}
