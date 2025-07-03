import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/dialogs/playlists/playlist_dialog_generic.dart';
import 'package:organista/features/show_playlists/cubit/playlists_cubit.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

void showAddPlaylistDialog(
    {required BuildContext context, required TextEditingController controller, required String userId}) {
  final localizations = context.loc;
  controller.text = '';
  showPlaylistDialog(
    context: context,
    controller: controller,
    title: localizations.newPlaylist,
    actionLabel: localizations.add,
    onConfirm: () {
      context.read<ShowPlaylistsCubit>().addPlaylist(
            playlistName: controller.text.trim(),
            userId: userId,
          );
    },
  );
}
