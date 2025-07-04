import 'package:flutter/material.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

Future<dynamic> showPlaylistDialog({
  required BuildContext context,
  required TextEditingController controller,
  required String title, // Dialog title (Add or Rename)
  required String actionLabel, // Button label (Add or Rename)
  required VoidCallback onConfirm, // Action to perform when confirmed
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
            labelText: localizations.playlistName,
            hintText: localizations.enterPlaylistName,
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
              final playlistName = controller.text.trim();
              if (playlistName.isNotEmpty) {
                onConfirm(); // Execute passed function
                controller.clear();
                Navigator.of(context).pop(); // Close the dialog
              } else {
                showErrorDialog(context, localizations.playlistNameEmpty);
              }
            },
            child: Text(actionLabel),
          ),
        ],
      );
    },
  );
}
