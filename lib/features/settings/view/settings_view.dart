import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/delete_account_dialog.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/l10n/app_localizations.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final settingsCubit = context.read<SettingsCubit>();

    return Scaffold(
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
                child: Text(
                  localizations.appSettings,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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

              // Account Management Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  localizations.accountManagement,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
                title: Text(
                  localizations.deleteAccount,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  final shouldDeleteAccount = await showDeleteAccountDialog(context);
                  if (shouldDeleteAccount && context.mounted) {
                    context.read<AppBloc>().add(
                          const AppEventDeleteAccount(),
                        );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
