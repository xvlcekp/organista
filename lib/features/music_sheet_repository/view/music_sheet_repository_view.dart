import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_bloc.dart';
import 'package:organista/features/music_sheet_repository/view/repository_music_sheet_tile_view.dart';
import 'package:organista/features/music_sheet_repository/view/searchbar.dart';
import 'package:organista/features/music_sheet_repository/view/upload_music_sheet_fragment.dart';
import 'package:organista/models/repositories/repository.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text('♬ ${repository.name}'),
      ),
      floatingActionButton: repository.isPrivate
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
                }
                if (state is MusicSheetRepositoryLoaded) {
                  return SafeArea(
                    child: ListView.builder(
                      itemCount: state.filteredMusicSheets.length,
                      itemBuilder: (context, index) {
                        final musicSheet = state.filteredMusicSheets[index];
                        return RepositoryMusicSheetTile(
                          musicSheet: musicSheet,
                          searchBarController: searchBarController,
                          repositoryId: repositoryId,
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
    );
  }
}
