import 'package:flutter/material.dart';
import 'package:organista/dialogs/text_input_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

Future<String?> showAddCustomRepositoryDialog({
  required BuildContext context,
}) {
  final localizations = context.loc;
  return showTextInputDialog(
    context: context,
    title: localizations.newRepository,
    actionLabel: localizations.add,
    labelText: localizations.repositoryName,
    hintText: localizations.enterRepositoryName,
  );
}
