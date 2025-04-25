import 'package:flutter/material.dart';
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

Future<void> showErrorDialog(
  BuildContext context,
  String text,
) {
  final localizations = context.loc;
  return showGenericDialog<void>(
    context: context,
    title: localizations.anErrorHappened,
    content: text,
    optionsBuilder: () => {
      localizations.ok: null,
    },
  );
}
