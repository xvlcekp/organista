import 'package:flutter/material.dart';
import 'package:organista/dialogs/text_input_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

Future<String?> showAddPlaylistDialog({
  required BuildContext context,
}) {
  final localizations = context.loc;
  return showTextInputDialog(
    context: context,
    title: localizations.newPlaylist,
    actionLabel: localizations.add,
    labelText: localizations.playlistName,
    hintText: localizations.enterPlaylistName,
  );
}
