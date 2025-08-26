import 'package:flutter/material.dart';
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/extensions/buildcontext/loc.dart';
import 'package:organista/models/repositories/repository.dart';

Future<bool> showDeleteRepositoryDialog({
  required BuildContext context,
  required Repository repository,
}) async {
  final localizations = context.loc;

  return showGenericDialog<bool>(
    context: context,
    title: localizations.deleteRepository,
    content: localizations.deleteRepositoryMessage(repository.name),
    optionsBuilder: () => {
      localizations.cancel: false,
      localizations.deleteRepository: true,
    },
  ).then(
    (value) => value ?? false,
  );
}
