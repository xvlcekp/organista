import 'package:organista/logger/custom_logger.dart';
import 'package:organista/services/auth/auth_provider.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/services/auth/auth_error.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, FirebaseAuthException, GoogleAuthProvider;
import 'package:google_sign_in/google_sign_in.dart';

// TODO - unify auth error messages in general, ideally do not throw custom errors (see how Vandad deals with that)

class FirebaseAuthProvider implements AuthProvider {
  @override
  Future<void> initialize() async {
    return;
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
      throw AuthErrorUserNotLoggedIn();
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
      throw AuthErrorUserNotLoggedIn();
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    logger.i('Starting Google Sign-In process');

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Clear any previous account selection to force account picker
      try {
        await googleSignIn.signOut();
        logger.d('Cleared previous Google Sign-In session');
      } catch (e) {
        logger.w('Failed to clear previous Google session: $e');
        // Continue anyway as this is not critical
      }

      // Step 1: Google account selection
      logger.d('Requesting Google account selection');
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        logger.e('Google account selection failed: $e');
        throw const AuthErrorGoogleSignInFailed();
      }

      if (googleUser == null) {
        logger.w('Google Sign-In cancelled by user');
        throw const AuthErrorGoogleSignInFailed();
      }

      logger.d('Google account selected: ${googleUser.email}');

      // Step 2: Get authentication tokens
      logger.d('Retrieving Google authentication tokens');
      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        logger.e('Failed to retrieve Google authentication tokens: $e');
        throw const AuthErrorGoogleSignInFailed();
      }

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        logger.e('Google authentication tokens are null');
        throw const AuthErrorGoogleSignInFailed();
      }

      logger.d('Google authentication tokens retrieved successfully');

      // Step 3: Create Firebase credential
      logger.d('Creating Firebase credential');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Sign in to Firebase
      logger.d('Signing in to Firebase with Google credential');
      try {
        await FirebaseAuth.instance.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        logger.e('Firebase sign-in failed: ${e.code} - ${e.message}');
        throw AuthError.from(e);
      } catch (e) {
        logger.e('Firebase sign-in failed with unexpected error: $e');
        throw const AuthErrorGoogleSignInFailed();
      }

      // Step 5: Verify user is signed in
      final user = currentUser;
      if (user != null) {
        logger.i('Google Sign-In completed successfully for user: ${user.email}');
        return user;
      } else {
        logger.e('User is null after successful Firebase sign-in');
        throw AuthErrorUserNotLoggedIn();
      }
    } catch (e) {
      // If it's already an AuthError, rethrow it
      if (e is AuthError) {
        rethrow;
      }

      // Log and wrap any other unexpected errors
      logger.e('Unexpected error during Google Sign-In: $e');
      throw const AuthErrorGoogleSignInFailed();
    }
  }

  @override
  Future<void> logOut() async {
    final user = currentUser;
    if (user != null) {
      // Sign out from both Firebase and Google
      await Future.wait([
        FirebaseAuth.instance.signOut(),
        GoogleSignIn().signOut(),
      ]);
    } else {
      throw AuthErrorUserNotLoggedIn();
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    } else {
      throw AuthErrorUserNotLoggedIn();
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
          await Future.wait([
            FirebaseAuth.instance.signOut(),
            GoogleSignIn().signOut(),
          ]);
        } catch (_) {
          logger.i('Ignoring sign-out errors during deletion');
        }
        rethrow;
      }
    } else {
      throw AuthErrorUserNotLoggedIn();
    }
  }
}
