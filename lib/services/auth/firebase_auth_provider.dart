import 'package:organista/logger/custom_logger.dart';
import 'package:organista/services/auth/auth_provider.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/services/auth/auth_error.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, FirebaseAuthException, GoogleAuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

// TODO - unify auth error messages in general, ideally do not throw custom errors (see how Vandad deals with that)

class FirebaseAuthProvider implements AuthProvider {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  Future<void> initialize() {
    return _googleSignIn.initialize().then((_) {
      logger.d('Google Sign-In initialized for authentication');
    });
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = currentUser;
    if (user != null) {
      return user;
    } else {
      throw const AuthErrorUserNotLoggedIn();
    }
  }

  @override
  AuthUser? get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AuthUser.fromFirebase(user);
    }
    return null;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = currentUser;
    if (user != null) {
      return user;
    } else {
      throw const AuthErrorUserNotLoggedIn();
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    logger.i('Starting Google Sign-In process');

    try {
      // Clear any previous account selection to force account picker
      try {
        await _googleSignIn.signOut();
        logger.d('Cleared previous Google Sign-In session');
      } catch (e) {
        logger.w('Failed to clear previous Google session: $e');
        // Continue anyway as this is not critical
      }

      // Check if authenticate method is supported
      logger.d('Checking if authenticate method is supported');
      if (!_googleSignIn.supportsAuthenticate()) {
        logger.e('Authenticate method not supported on this platform');
        throw const AuthErrorGoogleSignInFailed();
      }

      // Use authenticate method for authentication only (no authorization scopes needed)
      logger.d('Starting Google authentication');
      GoogleSignInAccount googleUser;
      try {
        googleUser = await _googleSignIn.authenticate();
      } on GoogleSignInException catch (e, stackTrace) {
        logger.e('Google authentication failed: ${e.code} - ${e.description}');
        Error.throwWithStackTrace(const AuthErrorGoogleSignInFailed(), stackTrace);
      } catch (e, stackTrace) {
        logger.e('Google authentication failed: $e');
        Error.throwWithStackTrace(const AuthErrorGoogleSignInFailed(), stackTrace);
      }

      logger.d('Google account authenticated: ${googleUser.email}');

      // Get authentication tokens (ID token for authentication)
      logger.d('Getting Google authentication tokens');
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        logger.e('Google ID token is null');
        throw const AuthErrorGoogleSignInFailed();
      }

      logger.d('Google authentication tokens retrieved successfully');

      // Create Firebase credential and sign in (we only need ID token for authentication)
      return await _signInToFirebaseWithGoogleCredential(idToken);
    } catch (e, stackTrace) {
      // If it's already an AuthError, rethrow it
      if (e is AuthError) {
        rethrow;
      }

      // Log and wrap any other unexpected errors
      logger.e('Unexpected error during Google Sign-In: $e');
      Error.throwWithStackTrace(const AuthErrorGoogleSignInFailed(), stackTrace);
    }
  }

  /// Signs in to Firebase using Google credentials
  Future<AuthUser> _signInToFirebaseWithGoogleCredential(String idToken) async {
    // Create Firebase credential
    logger.d('Creating Firebase credential');
    final credential = GoogleAuthProvider.credential(
      idToken: idToken, // Required for authentication
    );

    // Sign in to Firebase
    logger.d('Signing in to Firebase with Google credential');
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e, stackTrace) {
      logger.e('Firebase sign-in failed: ${e.code} - ${e.message}');
      Error.throwWithStackTrace(AuthError.from(e), stackTrace);
    } catch (e, stackTrace) {
      logger.e('Firebase sign-in failed with unexpected error: $e');
      Error.throwWithStackTrace(const AuthErrorGoogleSignInFailed(), stackTrace);
    }

    // Verify user is signed in
    final user = currentUser;
    if (user != null) {
      logger.i('Google Sign-In completed successfully for user: ${user.email}');
      return user;
    } else {
      logger.e('User is null after successful Firebase sign-in');
      throw const AuthErrorUserNotLoggedIn();
    }
  }

  @override
  Future<void> logOut() async {
    final user = currentUser;
    if (user != null) {
      // Sign out from both Firebase and Google (fire and forget for instant UI response)
      await FirebaseAuth.instance.signOut();
      unawaited(_googleSignIn.signOut());
    } else {
      throw const AuthErrorUserNotLoggedIn();
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    } else {
      throw const AuthErrorUserNotLoggedIn();
    }
  }

  @override
  Future<bool> sendPasswordResetEmail({required String email}) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    return true;
  }

  @override
  Future<void> deleteUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.delete();
      } catch (e) {
        // If user deletion fails, try to sign out first then delete
        try {
          await _googleSignIn.signOut();
        } catch (_) {
          logger.i('Ignoring sign-out errors during deletion');
        }
        rethrow;
      }
    } else {
      throw const AuthErrorUserNotLoggedIn();
    }
  }
}
