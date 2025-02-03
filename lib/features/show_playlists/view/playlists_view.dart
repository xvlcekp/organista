import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/playlists/add_playlist_dialog.dart';
import 'package:organista/dialogs/playlists/edit_playlist_dialog.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/show_playlist/view/playlist_view.dart';
import 'package:organista/features/show_playlists/cubit/playlists_cubit.dart';
import 'package:organista/views/main_popup_menu_button.dart';

class PlaylistsView extends HookWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = useTextEditingController();
    final User user = context.read<AppBloc>().state.user!;
    final String userId = user.uid;

    useEffect(() {
      // initialize stream only once on first creation
      context.read<ShowPlaylistsCubit>().startSubscribingPlaylists(userId: userId);
      return null;
    }, []);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Playlists ♬♬♬'),
          actions: [
            const MainPopupMenuButton(),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FloatingActionButton(
            onPressed: () => showAddPlaylistDialog(context: context, controller: controller, userId: userId),
            child: Icon(Icons.add),
          ),
        ),
        body: BlocBuilder<ShowPlaylistsCubit, ShowPlaylistsState>(
          builder: (context, state) {
            return state.playlists.isEmpty
                ? const Center(child: Text('No playlists available.'))
                : ListView.separated(
                    itemCount: state.playlists.length,
                    itemBuilder: (context, index) {
                      String playlistName = state.playlists[index].name;
                      return ListTile(
                          title: Text(playlistName),
                          onLongPress: () {
                            controller.text = playlistName;
                            showEditPlaylistDialog(context: context, controller: controller, playlist: state.playlists[index]);
                          },
                          onTap: () {
                            context.read<PlaylistBloc>().add(InitPlaylistEvent(playlist: state.playlists[index], user: user));
                            Navigator.of(context).push<void>(PlaylistView.route());
                          });
                    },
                    separatorBuilder: (_, __) => Divider(),
                  );
          },
        ));
  }
}
