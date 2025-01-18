import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/blocs/music_sheet_bloc/music_sheet_bloc.dart';

class MusicSheetBlocProvider extends StatelessWidget {
  final Widget child;

  const MusicSheetBlocProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    User user = context.read<AppBloc>().state.user!; // Get the user ID from somewhere
    return MultiBlocProvider(
      providers: [
        BlocProvider<MusicSheetCubit>(
          create: (_) => MusicSheetCubit(userId: user.uid),
        ),
      ],
      child: child,
    );
  }
}
