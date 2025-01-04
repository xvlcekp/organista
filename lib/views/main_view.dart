import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/managers/image_cache_manager.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:organista/views/download_image_view.dart';
import 'package:organista/views/main_popup_menu_button.dart';
import 'package:organista/views/music_sheet_list_tile.dart';

final logger = CustomLogger.instance;

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
    final firebaseStorageRepository = context.read<FirebaseStorageRepository>();

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
          logger.i("Item count is ${state.musicSheets?.length}");
          var musicSheets = (state.musicSheets ?? []).toList();
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(top: 10),
            itemCount: musicSheets.length,
            itemBuilder: (context, index) {
              final musicSheet = musicSheets.elementAt(index);
              Reference image = firebaseStorageRepository.getReference(musicSheet.originalFileStorageId);
              // Cache future for this image if not already cached
              cachedFutures.value.putIfAbsent(image, () => ImageCacheManager().loadImage(image));

              return MusicSheetListTile(
                key: Key(musicSheet.musicSheetId),
                musicSheet: musicSheet,
                cachedFutures: cachedFutures,
                image: image,
                evenItemColor: evenItemColor,
                musicSheets: musicSheets,
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
