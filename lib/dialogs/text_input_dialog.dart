import 'package:flutter/material.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

Future<String?> showTextInputDialog({
  required BuildContext context,
  required String title, // Dialog title
  required String actionLabel, // Button label
  required String labelText,
  required String hintText,
  String initialText = '',
}) {
  final localizations = context.loc;
  final theme = Theme.of(context);
  final TextEditingController textController = TextEditingController(text: initialText);

  return showDialog<String>(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: textController,
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
              final input = textController.text.trim();
              if (input.isEmpty) {
                showErrorDialog(context: context, text: localizations.inputCannotBeEmpty);
                return; // Stop execution here
              } else if (input == initialText) {
                showErrorDialog(context: context, text: localizations.inputCannotBeSameAsCurrent);
                return; // Stop execution here
              } else {
                Navigator.of(context).pop(input); // Close the dialog
              }
            },
            child: Text(actionLabel),
          ),
        ],
      );
    },
  );
}
