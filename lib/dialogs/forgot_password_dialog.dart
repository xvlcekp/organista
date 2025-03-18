import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';

Future<void> showForgotPasswordDialog(BuildContext context, TextEditingController emailController) async {
  TextEditingController resetPasswordEmailController = TextEditingController();
  resetPasswordEmailController.text = emailController.text;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reset Password'),
      content: TextField(
        controller: resetPasswordEmailController,
        decoration: const InputDecoration(
          hintText: 'Enter your email',
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final email = resetPasswordEmailController.text.trim();
            if (email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter your email')),
              );
              return;
            }

            context.read<AppBloc>().add(
                  AppEventForgotPassword(email: email),
                );
            Navigator.of(context).pop();
          },
          child: const Text('Reset Password'),
        ),
      ],
    ),
  );
}
