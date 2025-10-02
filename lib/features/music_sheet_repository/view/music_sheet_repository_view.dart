import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/extensions/navigation/navigation_extensions.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_bloc.dart';
import 'package:organista/features/music_sheet_repository/view/repository_music_sheet_tile_view.dart';
import 'package:organista/features/music_sheet_repository/view/searchbar.dart';
import 'package:organista/features/music_sheet_repository/view/upload_music_sheet_fragment.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_playlist/view/playlist_view.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

class MusicSheetRepositoryView extends HookWidget {
  final Repository repository;

  const MusicSheetRepositoryView({
    super.key,
    required this.repository,
  });

  static Route<void> route({
    required Repository repository,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (context) => MusicSheetRepositoryBloc(
          firebaseFirestoreRepository: context.read<FirebaseFirestoreRepository>(),
        )..add(InitMusicSheetsRepositoryEvent(repositoryId: repository.repositoryId)),
        child: MusicSheetRepositoryView(repository: repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.loc;
    final searchBarController = useTextEditingController();
    final repositoryId = repository.repositoryId;

    // Selection state using hooks - track by music sheet ID instead of index
    final isSelectionMode = useState<bool>(false);
    final selectedMusicSheetIds = useState<Set<String>>({});

    // Helper functions
    void enterSelectionMode(String musicSheetId) {
      selectedMusicSheetIds.value = {...selectedMusicSheetIds.value, musicSheetId};
      isSelectionMode.value = true;
    }

    void toggleSelection(String musicSheetId) {
      if (!isSelectionMode.value) return;

      final newSelected = Set<String>.from(selectedMusicSheetIds.value);
      if (newSelected.contains(musicSheetId)) {
        newSelected.remove(musicSheetId);
      } else {
        newSelected.add(musicSheetId);
      }
      selectedMusicSheetIds.value = newSelected;

      // Exit selection mode if no items are selected
      if (newSelected.isEmpty) {
        isSelectionMode.value = false;
      }
    }

    void toggleSelectAll(List<String> allMusicSheetIds) {
      final currentVisible = selectedMusicSheetIds.value.where((id) => allMusicSheetIds.contains(id)).toSet();
      final allVisibleSelected = currentVisible.length == allMusicSheetIds.length && allMusicSheetIds.isNotEmpty;

      final newSelected = Set<String>.from(selectedMusicSheetIds.value);

      if (allVisibleSelected) {
        // Unselect all visible items
        for (final id in allMusicSheetIds) {
          newSelected.remove(id);
        }
      } else {
        // Select all visible items
        newSelected.addAll(allMusicSheetIds);
      }

      selectedMusicSheetIds.value = newSelected;

      // Exit selection mode if no items are selected
      if (newSelected.isEmpty) {
        isSelectionMode.value = false;
      }
    }

    void exitSelectionMode() {
      isSelectionMode.value = false;
      selectedMusicSheetIds.value = {};
    }

    int getSelectedCount() => selectedMusicSheetIds.value.length;

    bool isVisibleSelectAll(List<String> visibleIds) {
      if (visibleIds.isEmpty) return false;
      final visibleSelected = selectedMusicSheetIds.value.where((id) => visibleIds.contains(id)).toSet();
      return visibleSelected.length == visibleIds.length;
    }

    Future<void> addSelectedToPlaylist(BuildContext context, Playlist playlist, List<MusicSheet> musicSheets) async {
      context.read<PlaylistBloc>().add(
        AddMusicSheetsToPlaylistEvent(
          musicSheets: musicSheets,
          playlist: playlist,
        ),
      );
      Navigator.of(context).popUntilRoute<PlaylistView>(context);
    }

    Future<void> showPlaylistSelectionDialog(BuildContext context, List<MusicSheet> allMusicSheets) async {
      final playlist = context.read<PlaylistBloc>().state.playlist;
      final selectedMusicSheets = allMusicSheets
          .where((sheet) => selectedMusicSheetIds.value.contains(sheet.musicSheetId))
          .toList();

      // Use the original context that has access to the FirebaseFirestoreRepository
      await addSelectedToPlaylist(context, playlist, selectedMusicSheets);
      exitSelectionMode();
    }

    return PopScope<Object?>(
      canPop: !isSelectionMode.value,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isSelectionMode.value) {
          exitSelectionMode();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('♬ ${repository.name}'),
          leading: isSelectionMode.value
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: exitSelectionMode,
                )
              : null,
          automaticallyImplyLeading: !isSelectionMode.value,
          actions: [
            if (isSelectionMode.value) ...[
              BlocBuilder<MusicSheetRepositoryBloc, MusicSheetRepositoryState>(
                builder: (context, state) {
                  if (state is MusicSheetRepositoryLoaded) {
                    final visibleIds = state.filteredMusicSheets.map((sheet) => sheet.musicSheetId).toList();
                    final allVisibleSelected = isVisibleSelectAll(visibleIds);

                    return TextButton(
                      child: !allVisibleSelected
                          ? Text(localizations.selectAll, style: const TextStyle(color: Colors.blue))
                          : Text(localizations.unselectAll, style: const TextStyle(color: Colors.red)),
                      onPressed: () => toggleSelectAll(visibleIds),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              BlocBuilder<MusicSheetRepositoryBloc, MusicSheetRepositoryState>(
                builder: (context, repoState) {
                  return IconButton(
                    icon: const Icon(Icons.playlist_add),
                    onPressed: () {
                      final selectedCount = getSelectedCount();
                      if (selectedCount > 0 && repoState is MusicSheetRepositoryLoaded) {
                        showPlaylistSelectionDialog(context, repoState.filteredMusicSheets);
                      }
                    },
                  );
                },
              ),
            ],
          ],
        ),
        floatingActionButton: repository.isPrivate && !isSelectionMode.value
            ? Padding(
                padding: const EdgeInsets.only(bottom: 20.0, right: 8.0),
                child: UploadMusicSheetFragment(repositoryId: repositoryId),
              )
            : null,
        body: Column(
          children: [
            RepositorySearchbar(
              searchBarController: searchBarController,
              onSearch: (query) {
                context.read<MusicSheetRepositoryBloc>().add(
                  SearchMusicSheets(query: query),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<MusicSheetRepositoryBloc, MusicSheetRepositoryState>(
                builder: (context, state) {
                  if (state is MusicSheetRepositoryLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state is MusicSheetRepositoryError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (state is MusicSheetRepositoryLoaded) {
                    if (state.filteredMusicSheets.isEmpty) {
                      return Center(
                        child: Text(
                          localizations.noMusicSheets,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      );
                    }

                    return SafeArea(
                      child: ListView.builder(
                        itemCount: state.filteredMusicSheets.length,
                        itemBuilder: (context, index) {
                          final musicSheet = state.filteredMusicSheets[index];
                          final isSelected = selectedMusicSheetIds.value.contains(musicSheet.musicSheetId);

                          return RepositoryMusicSheetTile(
                            musicSheet: musicSheet,
                            searchBarController: searchBarController,
                            repositoryId: repositoryId,
                            isSelectionMode: isSelectionMode.value,
                            isSelected: isSelected,
                            onTap: () {
                              if (isSelectionMode.value) {
                                toggleSelection(musicSheet.musicSheetId);
                              }
                            },
                            onLongPress: () {
                              if (!isSelectionMode.value) {
                                enterSelectionMode(musicSheet.musicSheetId);
                              }
                            },
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
