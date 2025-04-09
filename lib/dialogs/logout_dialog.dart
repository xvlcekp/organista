import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/l10n/app_localizations.dart';

Future<bool> showLogOutDialog(BuildContext context) {
  final localizations = AppLocalizations.of(context);

  return showGenericDialog<bool>(
    context: context,
    title: localizations.logout,
    content: localizations.logoutMessage,
    optionsBuilder: () => {
      localizations.cancel: false,
      localizations.logout: true,
    },
  ).then(
    (value) => value ?? false,
  );
}
