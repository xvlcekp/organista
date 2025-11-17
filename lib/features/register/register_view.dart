import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/extensions/if_debugging.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/widgets/email_text_field.dart';
import 'package:organista/widgets/organista_logo.dart';
import 'package:organista/widgets/password_text_field.dart';

class RegisterView extends HookWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final registerPassword = AppConstants.debugRegisterPassword.ifDebugging;
    final registerEmail = AppConstants.debugRegisterEmail.ifDebugging;

    final emailController = useTextEditingController(text: registerEmail);
    final passwordController = useTextEditingController(text: registerPassword);
    final verifyPasswordController = useTextEditingController(text: registerPassword);

    final isPasswordVisible = useState(false);
    final isVerifyPasswordVisible = useState(false);
    final theme = Theme.of(context);
    final localizations = context.loc;

    return Scaffold(
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
                  const OrganistaLogo(),
                  const SizedBox(height: 24),
                  Text(
                    localizations.createAccount,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.signUpToGetStarted,
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
                  const SizedBox(height: 16),
                  // Verify Password Field
                  PasswordTextField(
                    controller: verifyPasswordController,
                    hintText: localizations.verifyPassword,
                    obscureText: !isVerifyPasswordVisible.value,
                    onToggleVisibility: () {
                      isVerifyPasswordVisible.value = !isVerifyPasswordVisible.value;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Register Button
                  ElevatedButton(
                    onPressed: () {
                      final email = emailController.text.trim();
                      final password = passwordController.text;
                      final verifyPassword = verifyPasswordController.text;

                      // Validate fields
                      if (email.isEmpty) {
                        showErrorDialog(context: context, text: localizations.emailRequired);
                        return;
                      }

                      if (password.isEmpty) {
                        showErrorDialog(context: context, text: localizations.passwordRequired);
                        return;
                      }

                      if (verifyPassword.isEmpty) {
                        showErrorDialog(context: context, text: localizations.verifyPasswordRequired);
                        return;
                      }

                      if (password != verifyPassword) {
                        showErrorDialog(context: context, text: localizations.passwordsDoNotMatch);
                        return;
                      }

                      context.read<AuthBloc>().add(
                        AuthEventRegister(
                          email: email,
                          password: password,
                        ),
                      );
                    },
                    style: theme.elevatedButtonTheme.style,
                    child: Text(
                      localizations.register,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        localizations.alreadyHaveAccount,
                        style: theme.textTheme.bodyLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(
                            const AuthEventGoToLogin(),
                          );
                        },
                        child: Text(
                          localizations.login,
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
    );
  }
}
