import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/delete_image_dialog.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_edit_music_sheet_view.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_bloc.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_event.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/l10n/app_localizations.dart';

class RepositoryMusicSheetTile extends StatelessWidget {
  final MusicSheet musicSheet;
  final String repositoryId;
  final TextEditingController searchBarController;

  const RepositoryMusicSheetTile({
    super.key,
    required this.musicSheet,
    required this.searchBarController,
    required this.repositoryId,
  });

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppBloc>().state.user!.uid;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => MusicSheetView(musicSheet: musicSheet, mode: MusicSheetViewMode.full),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: AutoSizeText(
                musicSheet.fileName,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.download_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: localizations.downloadTooltip,
                  onPressed: () {
                    context.read<AddEditMusicSheetCubit>().addMusicSheetToPlaylist(musicSheet: musicSheet);
                    Navigator.of(context).push<void>(AddEditMusicSheetView.route());
                  },
                ),
                if (musicSheet.userId == userId)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: localizations.deleteTooltip,
                    onPressed: () async {
                      final shouldDeleteMusicSheet = await showDeleteImageDialog(context);
                      if (shouldDeleteMusicSheet && context.mounted) {
                        context.read<MusicSheetRepositoryBloc>().add(DeleteMusicSheet(
                              musicSheet: musicSheet,
                              repositoryId: repositoryId,
                            ));
                        searchBarController.text = '';
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
