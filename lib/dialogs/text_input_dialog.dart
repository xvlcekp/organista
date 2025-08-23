import 'package:flutter/material.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

Future<dynamic> showTextInputDialog({
  required BuildContext context,
  required TextEditingController controller,
  required String title, // Dialog title
  required String actionLabel, // Button label
  required VoidCallback onConfirm, // Action to perform when confirmed
  required String labelText,
  required String hintText,
}) {
  final localizations = context.loc;
  final theme = Theme.of(context);
  return showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog without saving
            },
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            style: theme.elevatedButtonTheme.style,
            onPressed: () {
              final input = controller.text.trim();
              if (input.isNotEmpty) {
                onConfirm(); // Execute passed function
                controller.clear();
                Navigator.of(context).pop(); // Close the dialog
              } else {
                showErrorDialog(context: context, text: localizations.inputCannotBeEmpty);
              }
            },
            child: Text(actionLabel),
          ),
        ],
      );
    },
  );
}
