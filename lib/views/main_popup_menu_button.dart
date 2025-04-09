import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/dialogs/delete_account_dialog.dart';
import 'package:organista/dialogs/logout_dialog.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:organista/features/settings/view/settings_view.dart';
import 'package:organista/features/about/view/about_view.dart';

enum MenuAction { logout, deleteAccount, settings, about }

class MainPopupMenuButton extends StatelessWidget {
  const MainPopupMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
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
          case MenuAction.settings:
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsView(),
              ),
            );
            break;
          case MenuAction.about:
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AboutView(),
              ),
            );
            break;
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<MenuAction>(
            value: MenuAction.settings,
            child: Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                Text(localizations.settings),
              ],
            ),
          ),
          PopupMenuItem<MenuAction>(
            value: MenuAction.logout,
            child: Row(
              children: [
                const Icon(Icons.logout, size: 20),
                const SizedBox(width: 8),
                Text(localizations.logout),
              ],
            ),
          ),
          PopupMenuItem<MenuAction>(
            value: MenuAction.deleteAccount,
            child: Row(
              children: [
                const Icon(Icons.delete_forever, size: 20),
                const SizedBox(width: 8),
                Text(localizations.deleteAccount),
              ],
            ),
          ),
          PopupMenuItem<MenuAction>(
            value: MenuAction.about,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Text(localizations.about),
              ],
            ),
          ),
        ];
      },
    );
  }
}
