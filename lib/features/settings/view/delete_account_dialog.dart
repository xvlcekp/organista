import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

Future<bool> showDeleteAccountDialog(BuildContext context) {
  final localizations = context.loc;

  return showGenericDialog<bool>(
    context: context,
    title: localizations.deleteAccount,
    content: localizations.deleteAccountMessage,
    optionsBuilder: () => {
      localizations.cancel: false,
      localizations.deleteAccount: true,
    },
  ).then(
    (value) => value ?? false,
  );
}
