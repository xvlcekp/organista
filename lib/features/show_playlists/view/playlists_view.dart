import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/add_playlist_dialog.dart';
import 'package:organista/features/show_playlists/cubit/playlist_cubit.dart';
import 'package:organista/views/main_popup_menu_button.dart';

class PlaylistsView extends HookWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = useTextEditingController();
    final String userId = context.read<AppBloc>().state.user!.uid;
    context.read<PlaylistCubit>().startSubscribingPlaylists(userId: userId);
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
        body: BlocBuilder<PlaylistCubit, PlaylistState>(
          builder: (context, state) {
            return state.playlists.isEmpty
                ? const Center(child: Text('No playlists available.'))
                : ListView.builder(
                    itemCount: state.playlists.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(state.playlists[index].name),
                      );
                    },
                  );
          },
        ));
  }
}
