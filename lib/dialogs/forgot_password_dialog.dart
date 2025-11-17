import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

Future<void> showForgotPasswordDialog(BuildContext context, TextEditingController emailController) {
  final theme = Theme.of(context);
  final localizations = context.loc;
  TextEditingController resetPasswordEmailController = TextEditingController();
  resetPasswordEmailController.text = emailController.text;
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(
        localizations.resetPassword,
        style: theme.textTheme.titleLarge,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.resetPasswordMessage,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetPasswordEmailController,
              decoration: InputDecoration(
                hintText: localizations.enterEmailHint,
                prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.onSurface),
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
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          style: theme.elevatedButtonTheme.style,
          onPressed: () {
            final email = resetPasswordEmailController.text.trim();
            if (email.isEmpty) {
              showErrorDialog(context: context, text: localizations.pleaseEnterEmail);
              return;
            }

            context.read<AuthBloc>().add(
              AuthEventForgotPassword(email: email),
            );
            Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.passwordResetLinkSent),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          },
          child: Text(localizations.resetPassword),
        ),
      ],
    ),
  );
}
