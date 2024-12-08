import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:organista/bloc/app_bloc.dart';
import 'package:organista/bloc/app_event.dart';
import 'package:organista/bloc/app_state.dart';
import 'package:organista/dialogs/delete_image_dialog.dart';
import 'package:organista/extensions/string_extensions.dart';
import 'package:organista/managers/image_cache_manager.dart';
import 'package:organista/views/download_image_view.dart';
import 'package:organista/views/fullscreen_image_gallery.dart';
import 'package:organista/views/main_popup_menu_button.dart';
import 'package:organista/views/storage_image_view.dart';

class PhotoGalleryView extends HookWidget {
  PhotoGalleryView({super.key});

  final ImageCacheManager _cacheManager = ImageCacheManager();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color evenItemColor = colorScheme.primary.withOpacity(0.5);

    final picker = useMemoized(() => ImagePicker(), [key]);
    final List<Reference> images = context.watch<AppBloc>().state.images?.toList() ?? [];
    return Scaffold(
        appBar: AppBar(
          title: const Text('Photo Gallery'),
          actions: [
            IconButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DownloadImageView(cacheManager: _cacheManager),
                  ),
                );
              },
              icon: const Icon(
                Icons.add,
              ),
            ),
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
                          file: image.path,
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
        body: ReorderableListView.builder(
          padding: const EdgeInsets.only(top: 10),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images.elementAt(index);
            return GestureDetector(
              key: Key(image.name),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageGallery(
                      imageList: images, // Convert to Uint8List
                      initialIndex: index,
                      cacheManager: _cacheManager,
                    ),
                  ),
                );
              },
              child: ListTile(
                leading: SizedBox(
                  height: 200,
                  width: 70,
                  child: StorageImageView(
                    image: image,
                    cacheManager: _cacheManager,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                tileColor: evenItemColor,
                title: Text('Item $index and name ${image.name.lastChars(4)}'),
                trailing: IconButton(
                  onPressed: () async {
                    final shouldDeleteImage = await showDeleteImageDialog(context);
                    if (shouldDeleteImage && context.mounted) {
                      context.read<AppBloc>().add(
                            AppEventDeleteImage(
                              fileRefToDelete: image,
                            ),
                          );
                    }
                    return;
                  },
                  icon: const Icon(Icons.delete),
                ),
              ),
            );
          },
          onReorderStart: (_) => HapticFeedback.heavyImpact(),
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final Reference item = images.removeAt(oldIndex);
            images.insert(newIndex, item);
          },
        ));
  }
}
