import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

Future<bool> showDeletePlaylistDialog(BuildContext context) {
  final localizations = context.loc;
  return showGenericDialog<bool>(
    context: context,
    title: localizations.deletePlaylist,
    content: localizations.deletePlaylistMessage,
    optionsBuilder: () => {
      localizations.cancel: false,
      localizations.deletePlaylist: true,
    },
  ).then(
    (value) => value ?? false,
  );
}
