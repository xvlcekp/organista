import 'package:flutter/material.dart';

Future<dynamic> showPlaylistDialog({
  required BuildContext context,
  required TextEditingController controller,
  required String title, // Dialog title (Add or Rename)
  required String actionLabel, // Button label (Add or Rename)
  required VoidCallback onConfirm, // Action to perform when confirmed
}) {
  return showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Playlist Name',
            hintText: 'Enter playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog without saving
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final playlistName = controller.text.trim();
              if (playlistName.isNotEmpty) {
                onConfirm(); // Execute passed function
                controller.clear();
                Navigator.of(context).pop(); // Close the dialog
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playlist name cannot be empty'),
                  ),
                );
              }
            },
            child: Text(actionLabel),
          ),
        ],
      );
    },
  );
}
