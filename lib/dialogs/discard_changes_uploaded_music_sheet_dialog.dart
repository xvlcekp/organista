import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';

Future<bool> showDiscardUploadedMusicSheetChangesDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Discard changes',
    content: 'Are you sure you want to go back without saving changes? You cannot undo this operation!',
    optionsBuilder: () => {
      'Cancel': false,
      'Discard changes': true,
    },
  ).then(
    (value) => value ?? false,
  );
}
