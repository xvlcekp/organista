import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/features/settings/view/delete_account_dialog.dart';
import 'package:organista/features/cache_management/view/cache_management_page.dart';
import 'package:organista/features/musicxml_test/view/musicxml_test_view.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
import 'package:organista/features/settings/widgets/section_header.dart';
import 'package:organista/extensions/buildcontext/localization.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = context.loc;
    final settingsCubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

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
                SectionHeader(
                  title: localizations.appSettings,
                  icon: Icons.settings,
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(localizations.language),
                  trailing: DropdownButton<String>(
                    value: state.localeString,
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
                        settingsCubit.changeLanguage(languageCode);
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.palette),
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
                        settingsCubit.changeTheme(themeMode.index);
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.expand_sharp),
                  title: Text(context.loc.showNavigationArrows),
                  trailing: Switch(
                    value: state.showNavigationArrows,
                    onChanged: (bool value) {
                      settingsCubit.changeShowNavigationArrows(value);
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.stay_current_portrait),
                  title: Text(context.loc.keepScreenOn),
                  trailing: Switch(
                    value: state.keepScreenOn,
                    onChanged: (bool value) {
                      settingsCubit.changeKeepScreenOn(value);
                    },
                  ),
                ),

                // Storage Management Section
                SectionHeader(
                  title: localizations.storageManagement,
                  icon: Icons.storage,
                ),
                ListTile(
                  leading: const Icon(Icons.wifi_off),
                  title: Text(localizations.manageStoredMusicSheets),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CacheManagementPage(),
                      ),
                    );
                  },
                ),
                // MusicXML Test Section
                const SectionHeader(
                  title: 'Development',
                  icon: Icons.code,
                ),
                ListTile(
                  leading: const Icon(Icons.music_note),
                  title: const Text('MusicXML Test'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MusicXmlTestView(),
                      ),
                    );
                  },
                ),
                // Account Management Section
                SectionHeader(
                  title: localizations.accountManagement,
                  icon: Icons.person,
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: errorColor),
                  title: Text(
                    localizations.deleteAccount,
                    style: TextStyle(color: errorColor),
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
