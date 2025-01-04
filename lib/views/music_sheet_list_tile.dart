import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/delete_image_dialog.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:organista/views/fullscreen_image_gallery.dart';
import 'package:organista/views/storage_image_view.dart';

class MusicSheetListTile extends StatelessWidget {
  const MusicSheetListTile({
    super.key,
    required this.musicSheet,
    required this.cachedFutures,
    required this.image,
    required this.evenItemColor,
    required this.musicSheets,
  });

  final MusicSheet musicSheet;
  final ValueNotifier<Map<Reference, Future<Uint8List?>>> cachedFutures;
  final Reference image;
  final Color evenItemColor;
  final List<MusicSheet> musicSheets;

  @override
  Widget build(BuildContext context) {
    final firebaseStorageRepository = context.read<FirebaseStorageRepository>();
    return ListTile(
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
              imageList: musicSheets.map((musicSheet) => firebaseStorageRepository.getReference(musicSheet.originalFileStorageId)).toList(), // Convert to Uint8List
              initialIndex: musicSheet.sequenceId,
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
  }
}
