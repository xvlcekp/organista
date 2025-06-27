import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/config/config_controller.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/dialogs/forgot_password_dialog.dart';
import 'package:organista/extensions/buildcontext/loc.dart';
import 'package:organista/widgets/email_text_field.dart';
import 'package:organista/widgets/password_text_field.dart';

class LoginView extends HookWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    if (kDebugMode) {
      useEffect(() {
        void loadConfig() async {
          await Config.load();
          if (context.mounted) {
            emailController.text = Config.get('emailTesterUser') ?? '';
            passwordController.text = Config.get('passwordTesterUser') ?? '';
          }
        }

        loadConfig();
        return null;
      }, []);
    }

    final isPasswordVisible = useState(false);
    final theme = Theme.of(context);
    final localizations = context.loc;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.passwordResetSent == true) {
          showErrorDialog(context, localizations.passwordResetEmailSent);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo or App Name
                    Image.asset(
                      'assets/images/organista_icon_200x200.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      localizations.welcomeBack,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.signInToContinue,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Email Field
                    EmailTextField(
                      controller: emailController,
                      hintText: localizations.email,
                    ),
                    const SizedBox(height: 16),
                    // Password Field
                    PasswordTextField(
                      controller: passwordController,
                      hintText: localizations.password,
                      obscureText: !isPasswordVisible.value,
                      onToggleVisibility: () {
                        isPasswordVisible.value = !isPasswordVisible.value;
                      },
                    ),
                    const SizedBox(height: 8),
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => showForgotPasswordDialog(context, emailController),
                        child: Text(
                          localizations.forgotPassword,
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Login Button
                    ElevatedButton(
                      onPressed: () {
                        final email = emailController.text;
                        final password = passwordController.text;
                        context.read<AuthBloc>().add(
                              AuthEventLogIn(
                                email: email,
                                password: password,
                              ),
                            );
                      },
                      style: theme.elevatedButtonTheme.style,
                      child: Text(localizations.login),
                    ),
                    const SizedBox(height: 16),
                    // Google Sign-In Button
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(
                              const AuthEventSignInWithGoogle(),
                            );
                      },
                      icon: Image.asset(
                        'assets/images/gmail_icon.png',
                        width: 30,
                        height: 30,
                      ),
                      label: Text(localizations.signInWithGoogle),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: const Color(0xFFF2F2F2),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          localizations.noAccount,
                          style: theme.textTheme.bodyLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<AuthBloc>().add(
                                  const AuthEventGoToRegistration(),
                                );
                          },
                          child: Text(
                            localizations.register,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// PROMPT: please add textTheme.button to the app_theme.dart based on buttons from login_view.dart
