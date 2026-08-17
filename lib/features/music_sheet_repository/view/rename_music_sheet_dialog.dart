import 'package:flutter/material.dart';
import 'package:organista/dialogs/text_input_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

Future<String?> showRenameMusicSheetDialog({
  required BuildContext context,
  required String musicSheetName,
}) {
  final localizations = context.loc;

  return showTextInputDialog(
    context: context,
    initialText: musicSheetName,
    title: localizations.renameMusicSheet,
    actionLabel: localizations.rename,
    labelText: localizations.musicSheetName,
    hintText: localizations.enterMusicSheetName,
  );
}
