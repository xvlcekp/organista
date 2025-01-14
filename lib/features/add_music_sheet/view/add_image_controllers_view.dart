import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:organista/features/add_music_sheet/cubit/add_music_sheet_cubit.dart';
import 'package:organista/views/download_image_view.dart';

class AddImageControllersView extends HookWidget {
  const AddImageControllersView({super.key});

  @override
  Widget build(BuildContext context) {
    final picker = useMemoized(() => ImagePicker(), [key]);
    return Row(
      children: [
        Expanded(
          child: IconButton(
            onPressed: () {
              Navigator.of(context).push<void>(DownloadImageView.route());
            },
            icon: const Icon(Icons.add),
            iconSize: 150,
          ),
        ),
        Expanded(
          child: IconButton(
            onPressed: () async {
              final image = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image is! XFile) {
                throw ArgumentError('Unsupported file type: ${image.runtimeType}');
              }
              final uint8ListImage = await File(image.path).readAsBytes();
              if (context.mounted) {
                context.read<AddMusicSheetCubit>().newMusicSheet(
                      fileName: "Nota ${DateTime.now().millisecondsSinceEpoch}",
                      file: uint8ListImage,
                    );
              }
            },
            icon: const Icon(Icons.upload),
            iconSize: 150,
          ),
        ),
      ],
    );
  }
}
