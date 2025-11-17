import 'package:flutter/material.dart';
import 'package:organista/dialogs/text_input_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

Future<String?> showRenameRepositoryDialog({
  required BuildContext context,
  required String repositoryName,
}) async {
  final localizations = context.loc;

  return await showTextInputDialog(
    context: context,
    initialText: repositoryName,
    title: localizations.renameRepository,
    actionLabel: localizations.rename,
    labelText: localizations.repositoryName,
    hintText: localizations.enterRepositoryName,
  );
}
