import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/l10n/app_localizations.dart';

Future<bool> showDeletePlaylistDialog(BuildContext context) {
  final localizations = AppLocalizations.of(context);
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
