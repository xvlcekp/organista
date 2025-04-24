import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/features/show_repositories/cubit/repositories_cubit.dart';
import 'package:organista/views/main_popup_menu_button.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/features/show_repositories/view/repository_tile.dart';
import 'package:organista/l10n/app_localizations.dart';

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
    final User user = context.read<AppBloc>().state.user!;
    final String userId = user.uid;
    final selectedTabIndex = useState(0); // 0 for Global, 1 for Personal
    final localizations = AppLocalizations.of(context);

    useEffect(() {
      // initialize stream only once on first creation
      context.read<ShowRepositoriesCubit>().startSubscribingRepositories(userId: userId);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text('${localizations.repositories} 📁'),
        actions: const [
          MainPopupMenuButton(),
        ],
      ),
      body: BlocBuilder<ShowRepositoriesCubit, ShowRepositoriesState>(
        builder: (context, state) {
          return _buildRepositoryList(context, state, userId, selectedTabIndex.value);
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(localizations, selectedTabIndex),
    );
  }

  Widget _buildRepositoryList(BuildContext context, ShowRepositoriesState state, String userId, int selectedTabIndex) {
    final globalRepositories = state.repositories.where((repo) => repo.userId.isEmpty).toList();
    final personalRepositories = state.repositories.where((repo) => repo.userId == userId).toList();
    final currentRepositories = selectedTabIndex == 0 ? globalRepositories : personalRepositories;
    final localizations = AppLocalizations.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (currentRepositories.isEmpty) {
      return Center(
        child: Text(selectedTabIndex == 0 ? localizations.noGlobalRepositories : localizations.noPersonalRepositories),
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

  Widget _buildBottomNavBar(AppLocalizations localizations, ValueNotifier<int> selectedTabIndex) {
    return BottomNavigationBar(
      currentIndex: selectedTabIndex.value,
      onTap: (index) {
        selectedTabIndex.value = index;
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.public),
          label: localizations.global,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: localizations.personal,
        ),
      ],
    );
  }
}
