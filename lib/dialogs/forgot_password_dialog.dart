import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';

Future<void> showForgotPasswordDialog(BuildContext context, TextEditingController emailController) async {
  TextEditingController resetPasswordEmailController = TextEditingController();
  resetPasswordEmailController.text = emailController.text;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      title: const Text(
        'Reset Password',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetPasswordEmailController,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.email_outlined, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                isDense: true,
                filled: true,
                fillColor: Colors.grey[100],
              ),
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 12.0), // Even smaller font size for input field
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
          ),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Reset Password'),
        ),
      ],
    ),
  );
}
