import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/dialogs/playlists/playlist_dialog_generic.dart';
import 'package:organista/features/show_playlists/cubit/playlists_cubit.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/l10n/app_localizations.dart';

showEditPlaylistDialog({required BuildContext context, required TextEditingController controller, required Playlist playlist}) {
  final localizations = AppLocalizations.of(context);

  showPlaylistDialog(
    context: context,
    controller: controller,
    title: localizations.renamePlaylist,
    actionLabel: localizations.rename,
    onConfirm: () {
      context.read<ShowPlaylistsCubit>().editPlaylistName(
            newPlaylistName: controller.text.trim(),
            playlist: playlist,
          );
    },
  );
}
