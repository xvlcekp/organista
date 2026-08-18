import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' show CacheManager;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/dialogs/delete_music_sheet_dialog.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_edit_music_sheet_view.dart';
import 'package:organista/features/music_sheet_repository/bloc/music_sheet_repository_bloc.dart';
import 'package:organista/features/music_sheet_repository/view/rename_music_sheet_dialog.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

class MusicSheetRepositoryTile extends HookWidget {
  final MusicSheet musicSheet;
  final String repositoryId;
  final TextEditingController searchBarController;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool viewOnly;

  static const int _selectedColorAlpha = 50;

  const MusicSheetRepositoryTile({
    super.key,
    required this.musicSheet,
    required this.searchBarController,
    required this.repositoryId,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.viewOnly = false,
  });

  Future<bool> _checkIfCached(CacheManager cacheManager) async {
    try {
      final file = await cacheManager.getFileFromCache(musicSheet.fileUrl);
      return file != null;
    } catch (e, stackTrace) {
      logger.e("Error checking cache for ${musicSheet.fileName}", error: e, stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user!.id;
    final theme = Theme.of(context);
    final localizations = context.loc;
    final isCached = useState<bool>(false);
    final primaryColor = theme.colorScheme.primary;
    final selectedColor = primaryColor.withAlpha(_selectedColorAlpha);
    final cacheManager = context.read<CacheManager>();

    useEffect(() {
      _checkIfCached(cacheManager).then((cached) {
        isCached.value = cached;
      });
      return null;
    }, [musicSheet.fileUrl]);

    return InkWell(
      onTap: isSelectionMode
          ? onTap
          : () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => SafeArea(
                        top: false,
                        child: MusicSheetView(source: MusicSheetUrlSource(musicSheet), mode: MusicSheetViewMode.full),
                      ),
                    ),
                  )
                  .then((_) {
                    // Check cache status after returning from the view
                    _checkIfCached(cacheManager).then((cached) {
                      isCached.value = cached;
                    });
                  });
            },
      onLongPress: isSelectionMode ? null : onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: AutoSizeText(
                musicSheet.fileName,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (isSelectionMode)
              Checkbox(
                value: isSelected,
                onChanged: (bool? value) => onTap?.call(),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCached.value)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  if (!viewOnly)
                    IconButton(
                      icon: Icon(
                        Icons.download_rounded,
                        color: primaryColor,
                      ),
                      tooltip: localizations.downloadMusicSheetTooltip,
                      onPressed: () {
                        context.read<AddEditMusicSheetCubit>().addMusicSheetToPlaylist(musicSheet: musicSheet);
                        Navigator.of(context).push<void>(AddEditMusicSheetView.route());
                      },
                    ),
                  if (musicSheet.userId == userId && viewOnly) ...[
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: primaryColor,
                      ),
                      tooltip: localizations.renameMusicSheetTooltip,
                      onPressed: () {
                        showRenameMusicSheetDialog(
                          context: context,
                          musicSheetName: musicSheet.fileName,
                        ).then((newName) {
                          if (newName != null && context.mounted) {
                            context.read<MusicSheetRepositoryBloc>().add(
                              RenameMusicSheet(
                                musicSheet: musicSheet,
                                fileName: newName,
                                repositoryId: repositoryId,
                              ),
                            );
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: localizations.deleteMusicSheetTooltip,
                      onPressed: () {
                        showDeleteMusicSheetDialog(context).then((shouldDeleteMusicSheet) {
                          if (shouldDeleteMusicSheet && context.mounted) {
                            context.read<MusicSheetRepositoryBloc>().add(
                              DeleteMusicSheet(
                                musicSheet: musicSheet,
                                repositoryId: repositoryId,
                              ),
                            );
                            searchBarController.text = '';
                          }
                        });
                      },
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
