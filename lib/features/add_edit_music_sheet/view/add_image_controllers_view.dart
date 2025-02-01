import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/download_music_sheet/view/download_image_view.dart';

class AddImageControllersView extends HookWidget {
  const AddImageControllersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: IconButton(
            onPressed: () {
              Navigator.of(context).push<void>(DownloadMusicSheetView.route());
            },
            icon: const Icon(Icons.add),
            iconSize: 150,
          ),
        ),
        Expanded(
          child: IconButton(
            onPressed: () => {},
            icon: const Icon(Icons.upload),
            iconSize: 150,
          ),
        ),
      ],
    );
  }
}
