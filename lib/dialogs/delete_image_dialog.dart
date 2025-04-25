import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

Future<bool> showDeleteImageDialog(BuildContext context) {
  final localizations = context.loc;

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
