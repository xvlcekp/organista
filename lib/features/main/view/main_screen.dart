import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/features/popup_menu/main_popup_menu_button.dart';
import 'package:organista/features/show_playlists/cubit/show_playlists_cubit.dart';
import 'package:organista/features/show_playlists/view/playlists_view.dart';
import 'package:organista/features/show_repositories/cubit/show_repositories_cubit.dart';
import 'package:organista/features/show_repositories/models/repositories_view_mode.dart';
import 'package:organista/features/show_repositories/view/repositories_view.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const double _appBarIconSpacing = 8.0;
  static const double _navigationBarHeight = 64.0;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = context.loc;
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ShowPlaylistsCubit(
            firebaseFirestoreRepository: context.read<FirebaseFirestoreRepository>(),
          ),
        ),
        BlocProvider(
          create: (_) => ShowRepositoriesCubit(
            firebaseFirestoreRepository: context.read<FirebaseFirestoreRepository>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(
                  _selectedIndex == 0 ? Icons.queue_music : Icons.folder_open,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: _appBarIconSpacing),
                Text(
                  _selectedIndex == 0 ? localizations.myPlaylists : localizations.repositories,
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            actions: const [MainPopupMenuButton()],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: const [
              PlaylistsView(),
              RepositoriesView(mode: RepositoriesViewMode.management),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            height: _navigationBarHeight,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.queue_music_outlined),
                selectedIcon: const Icon(Icons.queue_music),
                label: localizations.myPlaylists,
              ),
              NavigationDestination(
                icon: const Icon(Icons.folder_outlined),
                selectedIcon: const Icon(Icons.folder_open),
                label: localizations.repositories,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
