import 'package:organista/services/auth/auth_user.dart';

abstract class AuthProvider {
  Future<void> initialize();
  AuthUser? get currentUser;
  Future<AuthUser> logIn({
    required String email,
    required String password,
  });
  Future<AuthUser> createUser({
    required String email,
    required String password,
  });
  Future<AuthUser> signInWithGoogle();
  Future<void> logOut();
  Future<void> sendEmailVerification();
  Future<bool> sendPasswordResetEmail({required String email});
  Future<void> deleteUser();
}
