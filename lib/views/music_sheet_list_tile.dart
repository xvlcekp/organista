import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/dialogs/delete_image_dialog.dart';
import 'package:organista/features/add_music_sheet/bloc/music_sheet_bloc.dart';
import 'package:organista/features/add_music_sheet/view/add_music_sheet_view.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/views/fullscreen_image_gallery.dart';

class MusicSheetListTile extends StatelessWidget {
  const MusicSheetListTile({
    super.key,
    required this.musicSheet,
    required this.evenItemColor,
    required this.musicSheets,
  });

  final MusicSheet musicSheet;
  final Color evenItemColor;
  final List<MusicSheet> musicSheets;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        height: 200,
        width: 70,
        child: CachedNetworkImage(
          imageUrl: musicSheet.fileUrl,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          memCacheHeight: 200,
          memCacheWidth: 70,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      tileColor: evenItemColor,
      title: Text(musicSheet.fileName),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageGallery(
              musicSheets: musicSheets,
              initialIndex: musicSheet.sequenceId,
            ),
          ),
        );
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () async {
              if (context.mounted) {
                // TODO fix updating the same reference, doesn't work yet
                context.read<MusicSheetBloc>().add(EditMusicSheetEvent(musicSheet: musicSheet));
                Navigator.of(context).push<void>(AddMusicSheetView.route());
              }
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () async {
              final shouldDeleteImage = await showDeleteImageDialog(context);
              if (shouldDeleteImage && context.mounted) {
                context.read<MusicSheetBloc>().add(
                      DeleteMusicSheetEvent(
                        musicSheet: musicSheet,
                      ),
                    );
              }
              return;
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}
