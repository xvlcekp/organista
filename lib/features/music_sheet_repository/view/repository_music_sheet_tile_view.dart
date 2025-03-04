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

class RepositoryMusicSheetTile extends StatelessWidget {
  final MusicSheet musicSheet;
  final TextEditingController searchBarController;

  const RepositoryMusicSheetTile({
    super.key,
    required this.musicSheet,
    required this.searchBarController,
  });

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppBloc>().state.user!.uid;
    return ListTile(
      title: Text(musicSheet.fileName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              context.read<AddEditMusicSheetCubit>().addMusicSheetToPlaylist(musicSheet: musicSheet);
              Navigator.of(context).push<void>(AddEditMusicSheetView.route());
            },
          ),
          if (musicSheet.userId == userId) // Only show delete button if the user owns the file
            IconButton(
              onPressed: () async {
                final shouldDeleteMusicSheet = await showDeleteImageDialog(context);
                if (shouldDeleteMusicSheet && context.mounted) {
                  context.read<MusicSheetRepositoryBloc>().add(DeleteMusicSheet(musicSheet: musicSheet));
                  searchBarController.text = '';
                }
              },
              icon: const Icon(Icons.delete),
            ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => MusicSheetView(musicSheet: musicSheet, mode: MusicSheetViewMode.full),
        ));
      },
    );
  }
}
