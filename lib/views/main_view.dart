import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/features/add_music_sheet/view/add_music_sheet_view.dart';
import 'package:organista/views/main_popup_menu_button.dart';
import 'package:organista/views/music_sheet_list_tile.dart';

final logger = CustomLogger.instance;

class MainView extends HookWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color evenItemColor = colorScheme.primary.withOpacity(0.5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push<void>(AddMusicSheetView.route()),
            icon: const Icon(Icons.add),
          ),
          const MainPopupMenuButton(),
        ],
      ),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          logger.i("Item count is ${state.musicSheets?.length}");
          var musicSheets = (state.musicSheets ?? []).toList();
          return ReorderableListView(
            padding: const EdgeInsets.only(top: 10),
            onReorderStart: (_) => HapticFeedback.heavyImpact(),
            onReorder: (int oldIndex, int newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final MusicSheet item = musicSheets.removeAt(oldIndex);
              musicSheets.insert(newIndex, item);
              context.read<AppBloc>().add(AppEventReorderMusicSheet(musicSheets: musicSheets));
            },
            children: [
              for (int index = 0; index < musicSheets.length; index += 1)
                MusicSheetListTile(
                  key: Key(musicSheets.elementAt(index).musicSheetId),
                  musicSheet: musicSheets.elementAt(index),
                  evenItemColor: evenItemColor,
                  musicSheets: musicSheets,
                )
            ],
          );
        },
      ),
    );
  }
}
