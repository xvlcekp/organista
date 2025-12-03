import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:organista/managers/persistent_cache_manager.dart';
import 'package:organista/views/app.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:organista/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRepository extends StatelessWidget {
  const AppRepository({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FirebaseFirestoreRepository>(
          create: (context) => FirebaseFirestoreRepository(),
        ),
        RepositoryProvider<FirebaseStorageRepository>(
          create: (context) => FirebaseStorageRepository(),
        ),
        RepositoryProvider<SettingsRepository>(
          create: (context) => SettingsRepository(
            context.read<SharedPreferencesWithCache>(),
          ),
        ),
        RepositoryProvider<CacheManager>(
          create: (context) => PersistentCacheManager(),
        ),
      ],
      child: const App(),
    );
  }
}
