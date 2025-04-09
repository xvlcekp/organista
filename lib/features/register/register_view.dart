import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/extensions/if_debugging.dart';
import 'package:organista/l10n/app_localizations.dart';

class RegisterView extends HookWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController(
      text: 'test@test.com'.ifDebugging,
    );

    final passwordController = useTextEditingController(
      text: 'test123'.ifDebugging,
    );

    final isPasswordVisible = useState(false);
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

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
                  Icon(
                    Icons.music_note,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
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
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: localizations.email,
                      prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  // Password Field
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      hintText: localizations.password,
                      prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          isPasswordVisible.value = !isPasswordVisible.value;
                        },
                      ),
                    ),
                    obscureText: !isPasswordVisible.value,
                    obscuringCharacter: '◉',
                  ),
                  const SizedBox(height: 24),
                  // Register Button
                  ElevatedButton(
                    onPressed: () {
                      final email = emailController.text;
                      final password = passwordController.text;
                      context.read<AppBloc>().add(
                            AppEventRegister(
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
                          context.read<AppBloc>().add(
                                const AppEventGoToLogin(),
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
