import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/dialogs/show_auth_error.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/show_playlists/view/playlist_page.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/loading/loading_screen.dart';
import 'package:organista/features/login/login_view.dart';
import 'package:organista/features/register/register_view.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/repositories/firebase_auth_repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            firebaseFirestoreRepository: context.read<FirebaseFirestoreRepository>(),
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
            firebaseFirestoreRepository: context.read<FirebaseFirestoreRepository>(),
            firebaseStorageRepository: context.read<FirebaseStorageRepository>(),
          ),
        ),
        BlocProvider<SettingsCubit>(
          create: (context) => SettingsCubit(context.read<SharedPreferences>()),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: AppLocalizations.of(context).appTitle,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.themeMode,
            debugShowCheckedModeBanner: false,
            locale: settingsState.locale,
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('sk', ''), // Slovak
            ],
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: BlocConsumer<AppBloc, AppState>(
              listener: (context, appState) {
                if (appState.isLoading) {
                  LoadingScreen.instance().show(
                    context: context,
                    text: AppLocalizations.of(context).loading,
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
                  // this should never happen test
                  return Container();
                }
              },
            ),
            // TODO: named routes how to acces it - based on vandad's 1. video of state management course
            // use library https://pub.dev/packages/go_router for advanced routing
            // routes: {
            //   '/add-image':(context) => const
            // },
          );
        },
      ),
    );
  }
}
