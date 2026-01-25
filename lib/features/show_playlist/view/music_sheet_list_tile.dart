import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/dialogs/delete_image_dialog.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_edit_music_sheet_view.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/features/full_screen_gallery/view/fullscreen_image_gallery.dart';

class MusicSheetListTile extends HookWidget {
  const MusicSheetListTile({
    super.key,
    required this.index,
    required this.playlist,
    required this.isEditMode,
  });

  final int index;
  final Playlist playlist;
  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final musicSheet = playlist.musicSheets[index];
    const iconSize = 20.0;
    const musicSheetThumbnailSize = 40.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          if (!isEditMode) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FullScreenImageGallery(
                  musicSheets: playlist.musicSheets,
                  initialIndex: index,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                child: SizedBox.square(
                  dimension: musicSheetThumbnailSize,
                  child: MusicSheetView(
                    musicSheet: musicSheet,
                    mode: MusicSheetViewMode.thumbnail,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AutoSizeText(musicSheet.fileName),
              ),
              if (isEditMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.mounted) {
                          context.read<AddEditMusicSheetCubit>().editMusicSheetInPlaylist(
                            playlist: playlist,
                            musicSheet: musicSheet,
                          );
                          Navigator.of(context).push<void>(AddEditMusicSheetView.route());
                        }
                      },
                      icon: Icon(
                        Icons.edit,
                        size: iconSize,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showDeleteImageDialog(context).then((shouldDeleteImage) {
                          if (shouldDeleteImage && context.mounted) {
                            context.read<PlaylistBloc>().add(
                              DeleteMusicSheetInPlaylistEvent(
                                musicSheet: musicSheet,
                                playlist: playlist,
                              ),
                            );
                          }
                        });
                      },
                      icon: Icon(
                        Icons.delete,
                        size: iconSize,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
