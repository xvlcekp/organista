import 'package:flutter/material.dart';
import 'package:organista/dialogs/text_input_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

Future<String?> showEditPlaylistDialog({
  required BuildContext context,
  required String playlistName,
}) {
  final localizations = context.loc;

  return showTextInputDialog(
    context: context,
    initialText: playlistName,
    title: localizations.renamePlaylist,
    actionLabel: localizations.rename,
    labelText: localizations.playlistName,
    hintText: localizations.enterPlaylistName,
  );
}
