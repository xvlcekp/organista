import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:organista/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:organista/blocs/simple_bloc_observer.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/views/app_repository.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parallelize critical initialization
  final initFutures = await Future.wait([
    mainInitialize(),
    SharedPreferences.getInstance(),
  ]);

  final prefs = initFutures[1] as SharedPreferences;

  // Set up BLoC observer immediately (no heavy work)
  Bloc.observer = SimpleBlocObserver(logger: logger);

  // Start the app immediately
  runApp(
    Provider<SharedPreferences>.value(
      value: prefs,
      child: const AppRepository(),
    ),
  );

  // Setup logger asynchronously after app starts
  _setupLoggerAsync();
}

/// Setup logger in background without blocking app startup
void _setupLoggerAsync() {
  Future.microtask(() async {
    try {
      await logger.setup();
      logger.i('App started - logger initialized');
    } catch (e) {
      debugPrint('Logger setup failed: $e');
      // Don't crash the app if logging fails
    }
  });
}

/// This function must be called before using any Firebase services also in tests
Future<void> mainInitialize() async {
  // Firebase.initializeApp must be called before using any Firebase services
  await Firebase.initializeApp(
    options: await DefaultFirebaseOptions.currentPlatform,
  );
}
