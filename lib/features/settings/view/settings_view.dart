import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/auth_bloc/auth_bloc.dart';
import 'package:organista/dialogs/delete_account_dialog.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = context.loc;
    final settingsCubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);
    final titleMedium = theme.textTheme.titleMedium;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        // Pop the settings screen when user gets logged out (including account deletion)
        if (authState is AuthStateLoggedOut) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.settings),
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return ListView(
              children: [
                // App Settings Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(localizations.appSettings, style: titleMedium),
                ),
                ListTile(
                  title: Text(localizations.language),
                  trailing: DropdownButton<String>(
                    value: state.locale.languageCode,
                    items: [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(localizations.english),
                      ),
                      DropdownMenuItem(
                        value: 'sk',
                        child: Text(localizations.slovak),
                      ),
                    ],
                    onChanged: (String? languageCode) {
                      if (languageCode != null) {
                        settingsCubit.changeLanguage(Locale(languageCode));
                      }
                    },
                  ),
                ),
                ListTile(
                  title: Text(localizations.theme),
                  trailing: DropdownButton<ThemeMode>(
                    value: state.themeMode,
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(localizations.systemTheme),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(localizations.lightTheme),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(localizations.darkTheme),
                      ),
                    ],
                    onChanged: (ThemeMode? themeMode) {
                      if (themeMode != null) {
                        settingsCubit.changeTheme(themeMode);
                      }
                    },
                  ),
                ),
                ListTile(
                  title: Text(context.loc.showNavigationArrows),
                  trailing: Switch(
                    value: state.showNavigationArrows,
                    onChanged: (bool value) {
                      settingsCubit.changeShowNavigationArrows(value);
                    },
                  ),
                ),
                ListTile(
                  title: Text(context.loc.keepScreenOn),
                  trailing: Switch(
                    value: state.keepScreenOn,
                    onChanged: (bool value) {
                      settingsCubit.changeKeepScreenOn(value);
                    },
                  ),
                ),

                // Account Management Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(localizations.accountManagement, style: titleMedium),
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                  title: Text(
                    localizations.deleteAccount,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () {
                    showDeleteAccountDialog(context).then((shouldDeleteAccount) {
                      if (shouldDeleteAccount && context.mounted) {
                        context.read<AuthBloc>().add(
                          const AuthEventDeleteAccount(),
                        );
                      }
                    });
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
