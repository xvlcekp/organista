import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_bloc.dart';
import 'package:organista/features/music_sheet_repository/bloc/repository_event.dart';

class RepositorySearchbar extends StatelessWidget {
  const RepositorySearchbar({
    super.key,
    required this.searchBarController,
  });

  final TextEditingController searchBarController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchBarController,
        decoration: InputDecoration(
          hintText: 'Search music sheets...',
          border: InputBorder.none, // Removes the border
          enabledBorder: InputBorder.none, // Removes border when enabled
          focusedBorder: InputBorder.none, // Removes border when focused
          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
        ),
        style: TextStyle(color: theme.colorScheme.onSurface),
        onChanged: (query) {
          context.read<MusicSheetRepositoryBloc>().add(SearchMusicSheets(query: query));
        },
      ),
    );
  }
}
