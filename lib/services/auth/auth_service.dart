import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/services/auth/auth_provider.dart';
import 'package:organista/services/auth/firebase_auth_provider.dart';

class AuthService implements AuthProvider {
  const AuthService(this.provider);
  final AuthProvider provider;

  factory AuthService.firebase() => AuthService(FirebaseAuthProvider());

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) =>
      provider.createUser(
        email: email,
        password: password,
      );

  @override
  AuthUser? get currentUser => provider.currentUser;

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) =>
      provider.logIn(email: email, password: password);

  @override
  Future<void> logOut() => provider.logOut();

  @override
  Future<void> sendEmailVerification() => provider.sendEmailVerification();

  @override
  Future<void> initialize() => provider.initialize();

  @override
  Future<bool> sendPasswordResetEmail({required String email}) => provider.sendPasswordResetEmail(email: email);

  @override
  Future<void> deleteUser() => provider.deleteUser();
}
