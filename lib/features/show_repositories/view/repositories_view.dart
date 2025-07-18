import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/features/show_repositories/cubit/repositories_cubit.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/features/show_repositories/view/repository_tile.dart';
import 'package:organista/extensions/buildcontext/loc.dart';

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
    final selectedTabIndex = useState(0); // 0 for Global, 1 for Personal
    final localizations = context.loc;

    useEffect(() {
      // initialize stream only once on first creation
      context.read<ShowRepositoriesCubit>().startSubscribingRepositories(userId: userId);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text('${localizations.repositories} 📁'),
      ),
      body: BlocBuilder<ShowRepositoriesCubit, ShowRepositoriesState>(
        builder: (context, state) {
          return _buildRepositoryList(context, state, userId, selectedTabIndex.value);
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(context, selectedTabIndex),
    );
  }

  Widget _buildRepositoryList(BuildContext context, ShowRepositoriesState state, String userId, int selectedTabIndex) {
    final currentRepositories = selectedTabIndex == 0 ? state.publicRepositories : state.privateRepositories;
    final localizations = context.loc;
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

  Widget _buildBottomNavBar(BuildContext context, ValueNotifier<int> selectedTabIndex) {
    final localizations = context.loc;
    return NavigationBar(
      selectedIndex: selectedTabIndex.value,
      onDestinationSelected: (index) {
        selectedTabIndex.value = index;
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
