import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/dialogs/delete_image_dialog.dart';
import 'package:organista/features/add_edit_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_music_sheet_view.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/features/full_screen_gallery/fullscreen_image_gallery.dart';

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

    return ListTile(
      leading: SizedBox(
        height: 75,
        width: 75,
        child: MusicSheetView(
          musicSheet: musicSheet,
          mode: MusicSheetViewMode.thumbnail,
        ),
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
