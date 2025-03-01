import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_bloc.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_event.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_state.dart';
import 'package:organista/features/music_sheet_repository/view/repository_music_sheet_tile_view.dart';
import 'package:organista/features/music_sheet_repository/view/searchbar.dart';
import 'package:organista/features/music_sheet_repository/view/upload_music_sheet_fragment.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

class MusicSheetRepositoryView extends StatelessWidget {
  const MusicSheetRepositoryView({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const MusicSheetRepositoryView());
  }

  @override
  Widget build(BuildContext context) {
    final firebaseFirestoreRepository = context.read<FirebaseFirestoreRepository>();
    final userId = context.read<AppBloc>().state.user!.uid;

    return BlocProvider(
      create: (context) => MusicSheetRepositoryBloc(
        firebaseFirestoreRepository: firebaseFirestoreRepository,
      )..add(LoadMusicSheets(userId: userId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Repository ♬♬♬')),
        floatingActionButton: const Padding(
          padding: EdgeInsets.only(bottom: 20.0, right: 8.0),
          child: UploadMusicSheetFragment(),
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: RepositorySearchbar(),
            ),
            // Content (Loading, Error, or List)
            Expanded(
              child: BlocBuilder<MusicSheetRepositoryBloc, MusicSheetRepositoryState>(
                builder: (context, state) {
                  if (state is MusicSheetRepositoryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is MusicSheetRepositoryError) {
                    return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                  }
                  if (state is MusicSheetRepositoryLoaded && state.filteredMusicSheets.isEmpty) {
                    return const Center(child: Text("No music sheets found"));
                  }
                  if (state is MusicSheetRepositoryLoaded) {
                    return ListView.builder(
                      itemCount: state.filteredMusicSheets.length,
                      itemBuilder: (context, index) {
                        final musicSheet = state.filteredMusicSheets[index];
                        return RepositoryMusicSheetTile(musicSheet: musicSheet);
                      },
                    );
                  }
                  return const SizedBox(); // Fallback
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
