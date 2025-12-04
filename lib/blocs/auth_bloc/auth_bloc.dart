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

  void _authEventLogOut(AuthEventLogOut event, Emitter<AuthState> emit) async {
    try {
      emit(const AuthStateLoggedOut(isLoading: true));

      // Cancel all Firebase streams first to prevent permission errors
      await StreamManager.instance.cancelAllStreams();

      await _authProvider.logOut();
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
    await _authProvider.initialize();
    final user = _authProvider.currentUser;
    if (user == null) {
      emit(
        const AuthStateLoggedOut(isLoading: false),
      );
    } else {
      emit(
        AuthStateLoggedIn(
          isLoading: false,
          user: user,
        ),
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
