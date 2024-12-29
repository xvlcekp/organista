import 'package:flutter/material.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/blocs/app_bloc/app_state.dart';
import 'package:organista/blocs/music_sheet_bloc/music_sheet_bloc.dart';
import 'package:provider/provider.dart';

class MusicSheetBlocProvider extends StatelessWidget {
  final Widget child;

  const MusicSheetBlocProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    String userId = context.read<AppBloc>().state.user!.uid; // Get the user ID from somewhere
    return Provider<MusicSheetCubit>(
      create: (_) => MusicSheetCubit(userId: userId),
      dispose: (_, bloc) => bloc.close(),
      child: child,
    );
  }
}
