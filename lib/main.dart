import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:organista/blocs/simple_bloc_observer.dart';
import 'package:organista/firebase_options.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/views/app_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  CustomLogger log = CustomLogger.instance;
  await log.setup();
  Bloc.observer = SimpleBlocObserver(logger: log);
  log.i('App started');
  runApp(
    const AppRepository(),
  );
}

// TODO:
// Co v pripade viacerych stran na pesnicke
// PDF, alebo JPG? Kombinacia?
// globalny repositar s dodatocnymi info o piesnach
// otestovat flutter_cached_pdfview