import 'package:organista/services/auth/auth_provider.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/services/auth/auth_error.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, FirebaseAuthException, GoogleAuthProvider;
import 'package:google_sign_in/google_sign_in.dart';

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
    try {
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
    } on FirebaseAuthException catch (e) {
      throw AuthError.from(e);
    } catch (_) {
      throw const AuthGenericException();
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
    try {
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
    } on FirebaseAuthException catch (e) {
      throw AuthError.from(e);
    } catch (_) {
      throw const AuthGenericException();
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Clear any previous account selection to force account picker
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw const AuthGenericException();
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = currentUser;
      if (user != null) {
        return user;
      } else {
        throw AuthErrorUserNotLoggedIn();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthError.from(e);
    } catch (_) {
      throw const AuthGenericException();
    }
  }

  @override
  Future<void> logOut() async {
    final user = FirebaseAuth.instance.currentUser;
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

  // TODO: AuthError.form, how to fix it?
  @override
  Future<bool> sendPasswordResetEmail({required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      throw AuthError.from(e);
    } catch (_) {
      throw const AuthGenericException();
    }
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
          // Ignore sign-out errors during deletion
        }
        rethrow;
      }
    } else {
      throw AuthErrorUserNotLoggedIn();
    }
  }
}
