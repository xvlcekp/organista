import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

Future<bool> showDeleteMusicSheetDialog(BuildContext context) {
  final localizations = context.loc;

  return showGenericDialog<bool>(
    context: context,
    title: localizations.deleteMusicSheet,
    content: localizations.deleteMusicSheetMessage,
    optionsBuilder: () => {
      localizations.cancel: false,
      localizations.deleteMusicSheet: true,
    },
  ).then(
    (value) => value ?? false,
  );
}
