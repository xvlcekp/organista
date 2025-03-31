import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';

Future<void> showForgotPasswordDialog(BuildContext context, TextEditingController emailController) async {
  final theme = Theme.of(context);
  TextEditingController resetPasswordEmailController = TextEditingController();
  resetPasswordEmailController.text = emailController.text;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      title: Text(
        'Reset Password',
        style: theme.textTheme.titleLarge,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetPasswordEmailController,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                prefixIcon: Icon(Icons.email_outlined, size: 18, color: theme.colorScheme.onSurface),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.onSurface),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final email = resetPasswordEmailController.text.trim();
            if (email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter your email'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            context.read<AppBloc>().add(
                  AppEventForgotPassword(email: email),
                );
            Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset link sent to your email'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          },
          style: theme.elevatedButtonTheme.style?.copyWith(
            backgroundColor: WidgetStateProperty.all(theme.colorScheme.primary),
            foregroundColor: WidgetStateProperty.all(theme.colorScheme.onPrimary),
          ),
          child: const Text('Reset Password'),
        ),
      ],
    ),
  );
}
