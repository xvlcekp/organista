import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:organista/bloc/app_bloc.dart';
import 'package:organista/bloc/app_event.dart';
import 'package:organista/bloc/app_state.dart';
import 'package:organista/views/main_popup_menu_button.dart';
import 'package:organista/views/storage_image_view.dart';

class PhotoGalleryView extends HookWidget {
  const PhotoGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    final picker = useMemoized(() => ImagePicker(), [key]);
    final images = context.watch<AppBloc>().state.images ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        actions: [
          IconButton(
            onPressed: () async {
              final image = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image == null) {
                return;
              }
              if (context.mounted) {
                context.read<AppBloc>().add(
                      AppEventUploadImage(
                        filePathToUpload: image.path,
                      ),
                    );
              }
            },
            icon: const Icon(
              Icons.upload,
            ),
          ),
          const MainPopupMenuButton(),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(8),
        mainAxisSpacing: 20.0,
        crossAxisSpacing: 20.0,
        children: images
            .map(
              (img) => StorageImageView(
                image: img,
              ),
            )
            .toList(),
      ),
    );
  }
}
