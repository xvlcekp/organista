import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/forgot_password_dialog.dart';
import 'package:organista/extensions/if_debugging.dart';

class LoginView extends HookWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController(
      text: 'juststrawbery@gmail.com'.ifDebugging,
    );

    final passwordController = useTextEditingController(
      text: 'tester'.ifDebugging,
    );

    final isPasswordVisible = useState(false);
    final theme = Theme.of(context);

    return BlocListener<AppBloc, AppState>(
      listener: (context, state) {
        if (state.passwordResetSent == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password reset email sent. Please check your inbox.', style: theme.textTheme.bodyMedium)),
          );
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
                    Icon(
                      Icons.music_note,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back!',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
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
                        hintText: 'Email',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.colorScheme.onSurface),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    // Password Field
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
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
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.colorScheme.onSurface),
                        ),
                      ),
                      obscureText: !isPasswordVisible.value,
                      obscuringCharacter: '◉',
                    ),
                    const SizedBox(height: 8),
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => showForgotPasswordDialog(context, emailController),
                        child: Text(
                          'Forgot Password?',
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
                        context.read<AppBloc>().add(
                              AppEventLogIn(
                                email: email,
                                password: password,
                              ),
                            );
                      },
                      style: theme.elevatedButtonTheme.style,
                      child: const Text('Sign In'),
                    ),
                    const SizedBox(height: 16),
                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: theme.textTheme.bodyLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<AppBloc>().add(
                                  const AppEventGoToRegistration(),
                                );
                          },
                          child: Text(
                            'Sign Up',
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