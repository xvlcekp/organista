import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/dialogs/playlists/playlist_dialog_generic.dart';
import 'package:organista/features/show_playlists/cubit/playlist_cubit.dart';

showAddPlaylistDialog({required BuildContext context, required TextEditingController controller, required String userId}) {
  controller.text = '';
  showPlaylistDialog(
    context: context,
    controller: controller,
    title: 'Add New Playlist',
    actionLabel: 'Add',
    onConfirm: () {
      context.read<ShowPlaylistCubit>().addPlaylist(
            playlistName: controller.text.trim(),
            userId: userId,
          );
    },
  );
}
