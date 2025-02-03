import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/show_auth_error.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/show_playlists/view/playlist_page.dart';
import 'package:organista/loading/loading_screen.dart';
import 'package:organista/views/login_view.dart';
import 'package:organista/views/register_view.dart';
import 'package:organista/repositories/firebase_auth_repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';

class App extends StatelessWidget {
  const App({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(
          create: (context) => AppBloc(
            firebaseAuthRepository: context.read<FirebaseAuthRepository>(),
            firebaseFirestoreRepositary: context.read<FirebaseFirestoreRepository>(),
            firebaseStorageRepository: context.read<FirebaseStorageRepository>(),
          )..add(
              const AppEventInitialize(),
            ),
        ),
        BlocProvider<AddEditMusicSheetCubit>(
          create: (context) => AddEditMusicSheetCubit(),
        ),
        BlocProvider<PlaylistBloc>(
          create: (context) => PlaylistBloc(
            firebaseFirestoreRepositary: context.read<FirebaseFirestoreRepository>(),
            firebaseStorageRepository: context.read<FirebaseStorageRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Photo Library',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        debugShowCheckedModeBanner: false,
        home: BlocConsumer<AppBloc, AppState>(
          listener: (context, appState) {
            if (appState.isLoading) {
              LoadingScreen.instance().show(
                context: context,
                text: 'Loading...',
              );
            } else {
              LoadingScreen.instance().hide();
            }

            final authError = appState.authError;
            if (authError != null) {
              showAuthError(
                authError: authError,
                context: context,
              );
            }
          },
          builder: (context, appState) {
            if (appState is AppStateLoggedOut) {
              return const LoginView();
            } else if (appState is AppStateLoggedIn) {
              return const PlaylistPage();
            } else if (appState is AppStateIsInRegistrationView) {
              return const RegisterView();
            } else {
              // this should never happen
              return Container();
            }
          },
        ),
        // TODO: named routes how to acces it - based on vandad's 1. video of state management course
        // use library https://pub.dev/packages/go_router for advanced routing
        // routes: {
        //   '/add-image':(context) => const
        // },
      ),
    );
  }
}
