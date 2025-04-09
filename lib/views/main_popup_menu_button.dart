import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/delete_account_dialog.dart';
import 'package:organista/dialogs/logout_dialog.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/l10n/locale_provider.dart';

enum MenuAction { logout, deleteAccount, language }

class MainPopupMenuButton extends StatelessWidget {
  const MainPopupMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final localizations = AppLocalizations.of(context);

    return PopupMenuButton<MenuAction>(
      onSelected: (value) async {
        switch (value) {
          case MenuAction.logout:
            final shouldLogOut = await showLogOutDialog(context);
            if (shouldLogOut && context.mounted) {
              context.read<AppBloc>().add(
                    const AppEventLogOut(),
                  );
            }
            break;
          case MenuAction.deleteAccount:
            final shouldDeleteAccount = await showDeleteAccountDialog(context);
            if (shouldDeleteAccount && context.mounted) {
              context.read<AppBloc>().add(
                    const AppEventDeleteAccount(),
                  );
            }
            break;
          case MenuAction.language:
            // Show language selection dialog
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(localizations.language),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text(localizations.english),
                        onTap: () {
                          localeProvider.setLocale(const Locale('en', ''));
                          Navigator.of(context).pop();
                        },
                        trailing: localeProvider.locale.languageCode == 'en' ? const Icon(Icons.check) : null,
                      ),
                      ListTile(
                        title: Text(localizations.slovak),
                        onTap: () {
                          localeProvider.setLocale(const Locale('sk', ''));
                          Navigator.of(context).pop();
                        },
                        trailing: localeProvider.locale.languageCode == 'sk' ? const Icon(Icons.check) : null,
                      ),
                    ],
                  ),
                );
              },
            );
            break;
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<MenuAction>(
            value: MenuAction.language,
            child: Text(localizations.language),
          ),
          PopupMenuItem<MenuAction>(
            value: MenuAction.logout,
            child: Text(localizations.logout),
          ),
          PopupMenuItem<MenuAction>(
            value: MenuAction.deleteAccount,
            child: Text(localizations.deleteAccount),
          ),
        ];
      },
    );
  }
}
