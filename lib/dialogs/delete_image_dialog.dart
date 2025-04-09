import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/l10n/app_localizations.dart';

Future<bool> showDeleteImageDialog(BuildContext context) {
  final localizations = AppLocalizations.of(context);

  return showGenericDialog<bool>(
    context: context,
    title: localizations.deleteImage,
    content: localizations.deleteImageMessage,
    optionsBuilder: () => {
      localizations.cancel: false,
      localizations.deleteImage: true,
    },
  ).then(
    (value) => value ?? false,
  );
}
