import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/dialogs/delete_image_dialog.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_music_sheet_view.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/views/fullscreen_image_gallery.dart';
import 'package:organista/views/pdf_viewer_widget.dart';

class MusicSheetListTile extends HookWidget {
  const MusicSheetListTile({
    super.key,
    required this.index,
    required this.evenItemColor,
    required this.playlist,
  });

  final int index;
  final Color evenItemColor;
  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final musicSheet = playlist.musicSheets[index];

    Widget leadingWidget;

    if (musicSheet.mediaType == MediaType.image) {
      // If it's an image, display it using CachedNetworkImage
      leadingWidget = CachedNetworkImage(
        imageUrl: musicSheet.fileUrl,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error),
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        memCacheHeight: 75,
        memCacheWidth: 75,
      );
    } else {
      leadingWidget = PdfViewerWidget(fileUrl: musicSheet.fileUrl);
    }

    return ListTile(
      leading: SizedBox(
        height: 75,
        width: 75,
        child: leadingWidget,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      tileColor: evenItemColor,
      title: Text(musicSheet.fileName),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageGallery(
              musicSheets: playlist.musicSheets,
              initialIndex: index,
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
                context.read<AddEditMusicSheetCubit>().editMusicSheetInPlaylist(
                      playlist: playlist,
                      musicSheet: musicSheet,
                    );
                Navigator.of(context).push<void>(AddMusicSheetView.route());
              }
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () async {
              final shouldDeleteImage = await showDeleteImageDialog(context);
              if (shouldDeleteImage && context.mounted) {
                context.read<PlaylistBloc>().add(
                      DeleteMusicSheetInPlaylistEvent(
                        musicSheet: musicSheet,
                        playlist: playlist,
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
