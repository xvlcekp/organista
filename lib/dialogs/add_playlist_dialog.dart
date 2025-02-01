import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/show_playlists/cubit/playlist_cubit.dart';

// TODO: use generic dialog

Future<dynamic> showAddPlaylistDialog({
  required BuildContext context,
  required TextEditingController controller,
  required String userId,
}) {
  return showDialog(
      context: context,
      builder: (_) {
        // TODO: here was context, but the cubit actions didn't work, so I replaced it with _
        return AlertDialog(
          title: const Text('Add New Playlist'),
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
                  context.read<ShowPlaylistCubit>().addPlaylist(
                        playlistName: playlistName,
                        userId: userId,
                      );
                  controller.text = '';
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  // Show an error message if the name is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Playlist name cannot be empty'),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      });
}
