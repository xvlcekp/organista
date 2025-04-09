import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/l10n/app_localizations.dart';

Future<bool> showDiscardUploadedMusicSheetChangesDialog(BuildContext context) {
  final localizations = AppLocalizations.of(context);

  return showGenericDialog<bool>(
    context: context,
    title: localizations.discardChanges,
    content: localizations.discardChangesMessage,
    optionsBuilder: () => {
      localizations.cancel: false,
      localizations.discardChanges: true,
    },
  ).then(
    (value) => value ?? false,
  );
}
