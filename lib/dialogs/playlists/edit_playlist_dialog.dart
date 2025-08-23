import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/dialogs/text_input_dialog.dart';
import 'package:organista/features/show_playlists/cubit/playlists_cubit.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

void showEditPlaylistDialog({
  required BuildContext context,
  required Playlist playlist,
}) {
  final localizations = context.loc;
  final TextEditingController textController = TextEditingController(text: playlist.name);

  showTextInputDialog(
    context: context,
    controller: textController,
    title: localizations.renamePlaylist,
    actionLabel: localizations.rename,
    onConfirm: () {
      context.read<ShowPlaylistsCubit>().editPlaylistName(
        newPlaylistName: textController.text.trim(),
        playlist: playlist,
      );
    },
    labelText: localizations.playlistName,
    hintText: localizations.enterPlaylistName,
  );
}
