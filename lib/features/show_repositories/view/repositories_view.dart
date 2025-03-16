import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/features/music_sheet_repository/view/music_sheet_repository_view.dart';
import 'package:organista/features/show_repositories/cubit/repositories_cubit.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/views/main_popup_menu_button.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

class RepositoriesView extends HookWidget {
  const RepositoriesView({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const RepositoriesView());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShowRepositoriesCubit(
        firebaseFirestoreRepository: context.read<FirebaseFirestoreRepository>(),
      ),
      child: _RepositoriesViewContent(),
    );
  }
}

class _RepositoriesViewContent extends HookWidget {
  // List of vibrant colors for repository tiles
  final List<Color> _colors = [
    Colors.blue[400]!,
    Colors.red[400]!,
    Colors.green[400]!,
    Colors.orange[400]!,
    Colors.purple[400]!,
    Colors.teal[400]!,
    Colors.pink[400]!,
    Colors.indigo[400]!,
  ];

  Color _getRandomColor() {
    return _colors[math.Random().nextInt(_colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    final User user = context.read<AppBloc>().state.user!;
    final String userId = user.uid;

    useEffect(() {
      // initialize stream only once on first creation
      context.read<ShowRepositoriesCubit>().startSubscribingRepositories(userId: userId);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repositories 📁'),
        actions: [
          const MainPopupMenuButton(),
        ],
      ),
      body: BlocBuilder<ShowRepositoriesCubit, ShowRepositoriesState>(
        builder: (context, state) {
          if (state.repositories.isEmpty) {
            return const Center(child: Text('No repositories available.'));
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: state.repositories.length,
              itemBuilder: (context, index) {
                Repository repository = state.repositories[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MusicSheetRepositoryView.route(
                        repositoryId: repository.repositoryId,
                        repositoryName: repository.name,
                      ),
                      // RepositoryMusicSheetsView.route(
                      //   repositoryId: repository.repositoryId,
                      //   repositoryName: repository.name,
                      // ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getRandomColor(),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            Icons.folder,
                            size: 100,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                repository.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${repository.musicSheets.length} sheets',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
