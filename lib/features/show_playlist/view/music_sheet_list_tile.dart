import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/dialogs/delete_image_dialog.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_edit_music_sheet_view.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/features/full_screen_gallery/fullscreen_image_gallery.dart';

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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: MusicSheetView(
                    musicSheet: musicSheet,
                    mode: MusicSheetViewMode.thumbnail,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  musicSheet.fileName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isEditMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () async {
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
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
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
                      icon: Icon(
                        Icons.delete,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
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
