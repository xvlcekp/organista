import 'package:firebase_core/firebase_core.dart';
import 'package:organista/firebase_options.dart';
import 'package:organista/services/auth/auth_provider.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/services/auth/auth_error.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, FirebaseAuthException;

class FirebaseAuthProvider implements AuthProvider {
  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    try {
      FirebaseAuth.instance.createUserWithEmailAndPassword(
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
  Future<void> logOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuth.instance.signOut();
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
      await user.delete();
    } else {
      throw AuthErrorUserNotLoggedIn();
    }
  }
}
