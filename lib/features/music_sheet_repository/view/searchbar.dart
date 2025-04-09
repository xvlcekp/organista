import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/l10n/app_localizations.dart';

class RepositorySearchbar extends HookWidget {
  final TextEditingController searchBarController;
  final Function(String) onSearch;

  const RepositorySearchbar({
    super.key,
    required this.searchBarController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: searchBarController,
        decoration: InputDecoration(
          hintText: localizations.searchMusicSheets,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
        ),
        onChanged: onSearch,
      ),
    );
  }
}
