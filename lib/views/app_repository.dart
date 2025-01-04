import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/views/app.dart';

class AppRepository extends StatelessWidget {
  const AppRepository({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CustomLogger>(
          create: (context) => logger,
        ),
      ],
      child: const App(),
    );
  }
}
