import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:organista/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:organista/logger/simple_bloc_observer.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/views/app_repository.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first (required before any Firebase services)
  await firebaseInitialize();
  final SharedPreferencesWithCache prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );

  // Run app immediately - don't block on logger setup
  runApp(
    Provider<SharedPreferencesWithCache>.value(
      value: prefs,
      child: const AppRepository(),
    ),
  );

  // Setup logger after app starts (non-blocking)
  // This prevents blocking the UI thread during startup
  logger
      .setup()
      .then((_) {
        Bloc.observer = SimpleBlocObserver(logger: logger);
        logger.i('App started');
      })
      .catchError((error) {
        // Log error but don't crash - logging is not critical for app functionality
        debugPrint('Logger setup failed: $error');
      });
}

/// This function must be called before using any Firebase services also in tests
Future<void> firebaseInitialize() async {
  // Firebase.initializeApp must be called before using any Firebase services
  await Firebase.initializeApp(
    options: await DefaultFirebaseOptions.currentPlatform,
  );
}
