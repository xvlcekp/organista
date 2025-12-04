import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

Future<bool> showLogOutDialog(BuildContext context) {
  final localizations = context.loc;

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
