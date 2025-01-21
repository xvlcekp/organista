import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/download_music_sheet/view/download_image_view.dart';
import 'package:organista/logger/custom_logger.dart';

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
              Navigator.of(context).push<void>(DownloadMusicSheetView.route());
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
                if (context.mounted) {
                  CustomLogger.instance.i('Unsupported file type: ${image.runtimeType} while loading image from device');
                  context.read<AddEditMusicSheetCubit>().resetState();
                }
                return;
              }
              final uint8ListImage = await File(image.path).readAsBytes();
              if (context.mounted) {
                // TODO: image picker cannot load the original's file name
                context.read<AddEditMusicSheetCubit>().addMusicSheet(
                      fileName: image.name,
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
