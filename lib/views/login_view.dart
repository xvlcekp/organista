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

    return BlocListener<AppBloc, AppState>(
      listener: (context, state) {
        if (state.passwordResetSent == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset email sent. Please check your inbox.')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Log in',
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: 'Enter your email here...',
                ),
                keyboardType: TextInputType.emailAddress,
                keyboardAppearance: Brightness.dark,
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  hintText: 'Enter your password here...',
                ),
                keyboardAppearance: Brightness.dark,
                obscureText: true,
                obscuringCharacter: '◉',
              ),
              TextButton(
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
                child: const Text(
                  'Log in',
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<AppBloc>().add(
                        const AppEventGoToRegistration(),
                      );
                },
                child: const Text(
                  'Not registered yet? Register here!',
                ),
              ),
              TextButton(
                onPressed: () => showForgotPasswordDialog(context, emailController),
                child: const Text(
                  'Forgot password?',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
