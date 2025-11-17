import 'package:organista/logger/custom_logger.dart';
import 'package:organista/config/config_controller.dart';
import 'package:organista/services/auth/auth_service.dart';
import 'package:organista/services/auth/auth_user.dart';

class AuthUtils {
  AuthUtils();

  Future<AuthUser?> checkUserAuth() async {
    await ConfigController.load();

    final emailUploaderUser = ConfigController.get('emailUploaderUser') ?? '';
    final passwordUploaderUser = ConfigController.get('passwordUploaderUser') ?? '';
    logger.i(emailUploaderUser);

    await AuthService.firebase().logIn(
      email: emailUploaderUser,
      password: passwordUploaderUser,
    );
    final AuthUser? user = AuthService.firebase().currentUser;

    if (user == null) {
      logger.e("User is NOT authenticated.");
      return null;
    }
    logger.i("User is authenticated: ${user.id}");
    return user;
  }
}

// Create a singleton instance for use in the app
final authUtils = AuthUtils();
