import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';

class MusicSheetTile extends StatelessWidget {
  final MusicSheet musicSheet;

  const MusicSheetTile({super.key, required this.musicSheet});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(musicSheet.fileName),
      trailing: IconButton(
        icon: const Icon(Icons.download),
        onPressed: () {
          context.read<AddEditMusicSheetCubit>().addMusicSheetToPlaylist(musicSheet: musicSheet);
          Navigator.of(context).push<void>(AddMusicSheetView.route());
        },
      ),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => MusicSheetView(musicSheet: musicSheet, mode: MusicSheetViewMode.full),
        ));
      },
    );
  }
}
