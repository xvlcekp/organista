import 'package:firebase_auth/firebase_auth.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/repositories/firebase_auth_repository.dart';
import 'package:organista/config/config_controller.dart';

class AuthUtils {
  final FirebaseAuthRepository _authRepository;

  AuthUtils({FirebaseAuthRepository? authRepository}) : _authRepository = authRepository ?? FirebaseAuthRepository();

  Future<User?> checkUserAuth() async {
    await Config.load();

    final emailUploaderUser = Config.get('emailUploaderUser') ?? '';
    final passwordUploaderUser = Config.get('passwordUploaderUser') ?? '';
    logger.i(emailUploaderUser);

    await _authRepository.signInWithEmailAndPassword(
      email: emailUploaderUser,
      password: passwordUploaderUser,
    );
    final User? user = _authRepository.getCurrentUser();

    if (user == null) {
      logger.e("User is NOT authenticated.");
      return null;
    }
    logger.i("User is authenticated: ${user.uid}");
    return user;
  }
}

// Create a singleton instance for use in the app
final authUtils = AuthUtils();
