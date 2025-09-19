import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/dialogs/customRepositories/delete_repository_dialog.dart';
import 'package:organista/dialogs/customRepositories/rename_repository_dialog.dart';
import 'package:organista/dialogs/show_repositories_error.dart';
import 'package:organista/features/show_repositories/cubit/repositories_cubit.dart';
import 'package:organista/features/show_repositories/models/repository_error.dart';

import 'package:organista/logger/custom_logger.dart';
import 'package:provider/provider.dart';
import 'package:organista/features/music_sheet_repository/view/music_sheet_repository_view.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

class RepositoryTile extends StatelessWidget {
  final Repository repository;
  final int index;

  const RepositoryTile({
    super.key,
    required this.repository,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = context.loc;
    final currentUserId = context.read<AuthBloc>().state.user?.id ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MusicSheetRepositoryView.route(
            repository: repository,
          ),
        );
      },
      onLongPress: () {
        _showRepositoryContextMenu(context, currentUserId);
      },
      child: Container(
        decoration: BoxDecoration(
          color: _getFixedColor(),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
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
                color: Colors.white.withAlpha(40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    repository.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<int>(
                    future: _loadMusicSheetsCount(context),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withAlpha(200),
                            ),
                          ),
                        );
                      }

                      final count = snapshot.data ?? 0;
                      return Text(
                        '$count ${localizations.sheets}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _loadMusicSheetsCount(BuildContext context) async {
    try {
      return await context.read<FirebaseFirestoreRepository>().getRepositoryMusicSheetsCount(repository.repositoryId);
    } catch (e) {
      logger.e("Error loading music sheets count: $e");
      return 0;
    }
  }

  void _showRepositoryContextMenu(BuildContext context, String currentUserId) {
    final localizations = context.loc;
    final repositoriesCubit = context.read<ShowRepositoriesCubit>();

    // Only show menu for user's own repositories
    if (repository.userId.isEmpty || repository.userId != currentUserId) {
      showRepositoriesError(
        repositoryError: const RepositoryCannotModifyPublic(),
        context: context,
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(localizations.renameRepository),
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  final newName = await showRenameRepositoryDialog(
                    context: context,
                    repositoryName: repository.name,
                  );
                  if (newName != null) {
                    repositoriesCubit.renameRepository(
                      repositoryId: repository.repositoryId,
                      newName: newName,
                      currentUserId: currentUserId,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  localizations.deleteRepository,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  final shouldDelete = await showDeleteRepositoryDialog(context: context, repository: repository);
                  if (shouldDelete) {
                    repositoriesCubit.deleteRepository(
                      repositoryId: repository.repositoryId,
                      currentUserId: currentUserId,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getFixedColor() {
    final List<Color> colors = [
      Colors.blue[400]!,
      Colors.red[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.pink[400]!,
      Colors.indigo[400]!,
    ];
    // Use the index attribute to select a color, wrapping around if necessary
    return colors[index % colors.length];
  }
}
