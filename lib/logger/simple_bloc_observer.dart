import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SimpleBlocObserver extends BlocObserver {
  final CustomLogger logger;

  SimpleBlocObserver({required this.logger});

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // Only log state changes in debug mode to reduce overhead
    if (kDebugMode) {
      logger.d('${bloc.runtimeType} $change');
    }
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    // Only log transitions in debug mode
    if (kDebugMode) {
      logger.d('${bloc.runtimeType} $transition');
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    // Always log errors regardless of build mode
    logger.e('${bloc.runtimeType} $error', error: error, stackTrace: stackTrace);

    // Report BLoC errors to Sentry
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({'bloc_type': bloc.runtimeType.toString()}),
    );

    super.onError(bloc, error, stackTrace);
  }
}
