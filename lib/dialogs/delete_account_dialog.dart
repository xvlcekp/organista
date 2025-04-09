import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/l10n/app_localizations.dart';

Future<bool> showDeleteAccountDialog(BuildContext context) {
  final localizations = AppLocalizations.of(context);

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
