import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';

Future<bool> showDeleteImageDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Delete image',
    content: 'Are you sure you want to delete this image? You cannot undo this operation!',
    optionsBuilder: () => {
      'Cancel': false,
      'Delete image': true,
    },
  ).then(
    (value) => value ?? false,
  );
}
