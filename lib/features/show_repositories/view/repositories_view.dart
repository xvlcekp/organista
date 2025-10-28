import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/dialogs/customRepositories/add_custom_repository_dialog.dart';
import 'package:organista/dialogs/show_repositories_error.dart';
import 'package:organista/features/show_repositories/cubit/show_repositories_cubit.dart';
import 'package:organista/features/show_repositories/models/repository_tab_type.dart';
import 'package:organista/loading/loading_screen.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/features/show_repositories/view/repository_tile.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

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
      child: const RepositoriesViewContent(),
    );
  }
}

class RepositoriesViewContent extends HookWidget {
  const RepositoriesViewContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthUser user = context.read<AuthBloc>().state.user!;
    final String userId = user.id;
    final selectedTab = useState(RepositoryTabType.global);
    final localizations = context.loc;
    final theme = Theme.of(context);

    useEffect(() {
      // initialize stream only once on first creation
      context.read<ShowRepositoriesCubit>().startSubscribingRepositories(userId: userId);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text('${localizations.repositories} 📁'),
      ),
      body: BlocConsumer<ShowRepositoriesCubit, ShowRepositoriesState>(
        listener: (context, repositoryState) {
          if (repositoryState.isLoading) {
            LoadingScreen.instance().show(
              context: context,
              text: context.loc.loading,
            );
          } else {
            LoadingScreen.instance().hide();
          }

          final repositoryError = repositoryState.error;
          if (repositoryError != null) {
            showRepositoriesError(
              repositoryError: repositoryError,
              context: context,
            );
          }
        },
        builder: (context, state) {
          return _buildRepositoryList(context, state, selectedTab.value);
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(context, selectedTab),
      floatingActionButton: selectedTab.value.isPersonal
          ? FloatingActionButton.extended(
              onPressed: () {
                showAddCustomRepositoryDialog(context: context).then((repositoryName) {
                  if (repositoryName != null && context.mounted) {
                    context.read<ShowRepositoriesCubit>().createRepository(
                      repositoryName: repositoryName,
                      userId: userId,
                    );
                  }
                });
              },
              icon: const Icon(Icons.add),
              label: Text(localizations.newRepository),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            )
          : null,
    );
  }

  Widget _buildRepositoryList(
    BuildContext context,
    ShowRepositoriesState state,
    RepositoryTabType selectedTab,
  ) {
    final currentRepositories = selectedTab.isGlobal ? state.publicRepositories : state.privateRepositories;
    final localizations = context.loc;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (currentRepositories.isEmpty) {
      return Center(
        child: Text(
          selectedTab.isGlobal ? localizations.noGlobalRepositories : localizations.noPersonalRepositories,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLandscape ? 4 : 2,
          childAspectRatio: isLandscape ? 1.2 : 1.5,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: currentRepositories.length,
        itemBuilder: (context, index) {
          return RepositoryTile(repository: currentRepositories[index], index: index);
        },
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, ValueNotifier<RepositoryTabType> selectedTab) {
    final localizations = context.loc;
    return NavigationBar(
      selectedIndex: selectedTab.value.index,
      onDestinationSelected: (index) {
        selectedTab.value = RepositoryTabType.fromIndex(index);
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.public),
          label: localizations.global,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person),
          label: localizations.personal,
        ),
      ],
      height: 60,
    );
  }
}
