import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/show_playlists/cubit/playlists_cubit.dart';
import 'package:organista/features/show_playlists/view/playlists_view.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShowPlaylistsCubit(firebaseFirestoreRepository: context.read<FirebaseFirestoreRepository>()),
      child: const PlaylistsView(),
    );
  }
}
