import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_repositories/view/repositories_view.dart';
import 'package:organista/loading/loading_screen.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/playlists/playlist.dart';
import 'package:organista/features/show_playlist/view/music_sheet_list_tile.dart';

class PlaylistView extends StatelessWidget {
  const PlaylistView({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (context) => PlaylistView());
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color evenItemColor = colorScheme.primary.withOpacity(0.5);
    Playlist playlist = context.read<PlaylistBloc>().state.playlist;

    // context.read<MusicSheetBloc>().add(
    //       InitMusicSheetEvent(
    //         user: context.read<AppBloc>().state.user!,
    //       ),
    //     );

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push<void>(RepositoriesView.route());
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: BlocConsumer<PlaylistBloc, PlaylistState>(
        listener: (context, appState) {
          if (appState.isLoading) {
            LoadingScreen.instance().show(
              context: context,
              text: 'Loading...',
            );
          } else {
            LoadingScreen.instance().hide();
          }
        },
        builder: (context, state) {
          var playlist = state.playlist;
          logger.i("Item count is ${playlist.musicSheets.length}");
          return ReorderableListView(
            padding: const EdgeInsets.only(top: 10),
            onReorderStart: (_) => HapticFeedback.heavyImpact(),
            onReorder: (int oldIndex, int newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final MusicSheet item = playlist.musicSheets.removeAt(oldIndex);
              playlist.musicSheets.insert(newIndex, item);
              context.read<PlaylistBloc>().add(ReorderMusicSheetEvent(playlist: playlist));
            },
            children: [
              for (int index = 0; index < playlist.musicSheets.length; index += 1)
                MusicSheetListTile(
                  key: Key(playlist.musicSheets.elementAt(index).musicSheetId),
                  index: index,
                  evenItemColor: evenItemColor,
                  playlist: playlist,
                )
            ],
          );
        },
      ),
    );
  }
}
