import 'package:flutter/material.dart';
import 'package:organista/dialogs/text_input_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

/// Asks for the name of the copy; the suggested name is the original one with a "(copy)" suffix. The original
/// name itself is rejected so that two identically named playlists do not end up next to each other.
Future<String?> showDuplicatePlaylistDialog({
  required BuildContext context,
  required String playlistName,
}) {
  final localizations = context.loc;

  return showTextInputDialog(
    context: context,
    initialText: localizations.playlistCopyName(playlistName),
    currentText: playlistName,
    title: localizations.duplicatePlaylist,
    actionLabel: localizations.duplicate,
    labelText: localizations.playlistName,
    hintText: localizations.enterPlaylistName,
  );
}
