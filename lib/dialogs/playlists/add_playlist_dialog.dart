import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/dialogs/text_input_dialog.dart';
import 'package:organista/features/show_playlists/cubit/playlists_cubit.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

void showAddPlaylistDialog({
  required BuildContext context,
  required String userId,
}) {
  final localizations = context.loc;
  final TextEditingController textController = TextEditingController();
  /*  */
  showTextInputDialog(
    context: context,
    controller: textController,
    title: localizations.newPlaylist,
    actionLabel: localizations.add,
    onConfirm: () {
      context.read<ShowPlaylistsCubit>().addPlaylist(
        playlistName: textController.text.trim(),
        userId: userId,
      );
    },
    labelText: localizations.playlistName,
    hintText: localizations.enterPlaylistName,
  );
}
