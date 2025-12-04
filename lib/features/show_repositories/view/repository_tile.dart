import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/features/show_repositories/view/delete_repository_dialog.dart';
import 'package:organista/features/show_repositories/view/rename_repository_dialog.dart';
import 'package:organista/features/show_repositories/view/show_repositories_error.dart';
import 'package:organista/features/show_repositories/cubit/show_repositories_cubit.dart';
import 'package:organista/features/show_repositories/models/repository_error.dart';

import 'package:organista/logger/custom_logger.dart';
import 'package:provider/provider.dart';
import 'package:organista/features/music_sheet_repository/view/music_sheet_repository_view.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

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
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        ),
        child: Stack(
          children: [
            const _BackgroundIcon(icon: Icons.folder),
            _RepositoryCardContent(repository: repository),
          ],
        ),
      ),
    );
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
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  showRenameRepositoryDialog(
                    context: context,
                    repositoryName: repository.name,
                  ).then((newName) {
                    if (newName != null) {
                      repositoriesCubit.renameRepository(
                        repositoryId: repository.repositoryId,
                        newName: newName,
                        currentUserId: currentUserId,
                      );
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  localizations.deleteRepository,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  showDeleteRepositoryDialog(context: context, repository: repository).then((shouldDelete) {
                    if (shouldDelete) {
                      repositoriesCubit.deleteRepository(
                        repositoryId: repository.repositoryId,
                        currentUserId: currentUserId,
                      );
                    }
                  });
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
      Colors.blue.shade400,
      Colors.red.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
    ];
    // Use the index attribute to select a color, wrapping around if necessary
    return colors[index % colors.length];
  }
}

/// Decorative background icon for the repository card
class _BackgroundIcon extends StatelessWidget {
  final IconData icon;
  final double iconOffset = 20;
  final double iconSize = 100;
  final int iconOpacity = 40;

  const _BackgroundIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -iconOffset,
      bottom: -iconOffset,
      child: Icon(
        icon,
        size: iconSize,
        color: Colors.white.withAlpha(iconOpacity),
      ),
    );
  }
}

/// Content area of the repository card showing name and music sheets count
class _RepositoryCardContent extends StatelessWidget {
  final Repository repository;

  const _RepositoryCardContent({
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          ),
          const SizedBox(height: 8),
          _MusicSheetsCount(repository: repository),
        ],
      ),
    );
  }
}

/// Displays the count of music sheets in a repository with loading state
class _MusicSheetsCount extends StatelessWidget {
  final Repository repository;

  const _MusicSheetsCount({
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = context.loc;

    return FutureBuilder<int>(
      future: _loadMusicSheetsCount(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(),
          );
        }

        final count = snapshot.data ?? 0;
        return Text(
          '$count ${localizations.sheets(count)}',
          style: const TextStyle(color: Colors.white),
        );
      },
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
}
