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
  await logger.setup();
  Bloc.observer = SimpleBlocObserver(logger: logger);
  logger.i('App started');
  runApp(
    const AppRepository(),
  );
}

// TODO: format staihnutia z onedrivu https://onedrive.live.com/?id=FD3BD2FF7EA852EE%211739&resid=FD3BD2FF7EA852EE%211739&authkey=%21AMXgPV%5FBpTSE4bE&cid=fd3bd2ff7ea852ee&action=download 