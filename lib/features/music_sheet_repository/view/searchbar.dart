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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: searchBarController,
        decoration: const InputDecoration(
          hintText: 'Search music sheets...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white60),
          icon: Icon(Icons.search, color: Colors.white),
        ),
        style: const TextStyle(color: Colors.white),
        onChanged: (query) {
          context.read<MusicSheetRepositoryBloc>().add(SearchMusicSheets(query: query));
        },
      ),
    );
  }
}
