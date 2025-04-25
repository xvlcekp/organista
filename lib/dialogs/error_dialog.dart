import 'package:flutter/material.dart';
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/l10n/app_localizations.dart';

Future<void> showErrorDialog(
  BuildContext context,
  String text,
) {
  final localizations = AppLocalizations.of(context);
  return showGenericDialog<void>(
    context: context,
    title: localizations.anErrorHappened,
    content: text,
    optionsBuilder: () => {
      localizations.ok: null,
    },
  );
}
