import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

Future<bool> showDiscardUploadedMusicSheetChangesDialog(BuildContext context) {
  final localizations = context.loc;

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
