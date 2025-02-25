import 'package:flutter/material.dart' show BuildContext;
import 'package:organista/dialogs/generic_dialog.dart';

Future<bool> showDeletePlaylistDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Delete playlist',
    content: 'Are you sure you want to delete this playlist? You cannot undo this operation!',
    optionsBuilder: () => {
      'Cancel': false,
      'Delete playlist': true,
    },
  ).then(
    (value) => value ?? false,
  );
}
