import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/dialogs/show_auth_error.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/show_playlists/view/playlist_page.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/loading/loading_screen.dart';
import 'package:organista/features/login/login_view.dart';
import 'package:organista/features/register/register_view.dart';
import 'package:organista/logger/custom_logger.dart' show logger;
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:organista/services/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatelessWidget {
  const App({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(
                authProvider: AuthService.firebase(),
                firebaseFirestoreRepository: context.read<FirebaseFirestoreRepository>(),
                firebaseStorageRepository: context.read<FirebaseStorageRepository>(),
              )..add(
                const AuthEventInitialize(),
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
          create: (context) => SettingsCubit(context.read<SharedPreferencesWithCache>()),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            title: 'Organista',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.themeMode,
            debugShowCheckedModeBanner: false,
            locale: settingsState.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, authState) {
                if (authState.isLoading) {
                  LoadingScreen.instance().show(
                    context: context,
                    text: context.loc.loading,
                  );
                } else {
                  LoadingScreen.instance().hide();
                }

                final authError = authState.authError;
                if (authError != null) {
                  showAuthError(
                    authError: authError,
                    context: context,
                  );
                }
              },
              builder: (context, authState) {
                if (authState is AuthStateLoggedOut) {
                  return const LoginView();
                } else if (authState is AuthStateLoggedIn) {
                  return const PlaylistPage();
                } else if (authState is AuthStateIsInRegistrationView) {
                  return const RegisterView();
                } else {
                  // this should never happen test
                  logger.e('Unknown auth state: $authState');
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
