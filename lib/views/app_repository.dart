import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/views/app.dart';
import 'package:organista/repositories/firebase_auth_repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';

class AppRepository extends StatelessWidget {
  const AppRepository({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FirebaseAuthRepository>(
          create: (context) => FirebaseAuthRepository(),
        ),
        RepositoryProvider<FirebaseFirestoreRepository>(
          create: (context) => FirebaseFirestoreRepository(),
        ),
        RepositoryProvider<FirebaseStorageRepository>(
          create: (context) => FirebaseStorageRepository(),
        ),
      ],
      child: const App(),
    );
  }
}
