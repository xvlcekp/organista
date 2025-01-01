import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/delete_image_dialog.dart';
import 'package:organista/managers/image_cache_manager.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/views/download_image_view.dart';
import 'package:organista/views/fullscreen_image_gallery.dart';
import 'package:organista/views/main_popup_menu_button.dart';
import 'package:organista/views/storage_image_view.dart';

class MainView extends HookWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color evenItemColor = colorScheme.primary.withOpacity(0.5);

    final picker = useMemoized(() => ImagePicker(), [key]);
    // final List<Reference> images = context.watch<AppBloc>().state.images?.toList() ?? [];
    // Cache Futures for images
    final cachedFutures = useState<Map<Reference, Future<Uint8List?>>>(<Reference, Future<Uint8List?>>{});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        actions: [
          IconButton(
            onPressed: () async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DownloadImageView(),
                ),
              );
            },
            icon: const Icon(Icons.add),
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
                        fileName: "Nota ${DateTime.now().millisecondsSinceEpoch}",
                      ),
                    );
              }
            },
            icon: const Icon(Icons.upload),
          ),
          const MainPopupMenuButton(),
        ],
      ),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          print("Item count is ${state.musicSheets?.length}");
          var musicSheets = (state.musicSheets ?? []).toList();
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(top: 10),
            itemCount: musicSheets.length,
            itemBuilder: (context, index) {
              final musicSheet = musicSheets.elementAt(index);
              Reference image = FirebaseStorage.instance.ref(musicSheet.originalFileStorageId);
              // Cache future for this image if not already cached
              cachedFutures.value.putIfAbsent(image, () => ImageCacheManager().loadImage(image));

              return ListTile(
                key: Key(musicSheet.musicSheetId),
                leading: SizedBox(
                  height: 200,
                  width: 70,
                  child: StorageImageView(
                    imageFuture: cachedFutures.value[image]!,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                tileColor: evenItemColor,
                title: Text(musicSheet.fileName),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageGallery(
                        imageList: musicSheets.map((musicSheet) => FirebaseStorage.instance.ref(musicSheet.originalFileStorageId)).toList(), // Convert to Uint8List
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                trailing: IconButton(
                  onPressed: () async {
                    final shouldDeleteImage = await showDeleteImageDialog(context);
                    if (shouldDeleteImage && context.mounted) {
                      context.read<AppBloc>().add(
                            AppEventDeleteMusicSheet(
                              musicSheetToDelete: musicSheet,
                            ),
                          );
                    }
                    return;
                  },
                  icon: const Icon(Icons.delete),
                ),
              );
            },
            onReorderStart: (_) => HapticFeedback.heavyImpact(),
            onReorder: (int oldIndex, int newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final MusicSheet item = musicSheets.removeAt(oldIndex);
              musicSheets.insert(newIndex, item);
              context.read<AppBloc>().add(AppEventReorderMusicSheet(musicSheets: musicSheets));
            },
          );
        },
      ),
    );
  }
}
