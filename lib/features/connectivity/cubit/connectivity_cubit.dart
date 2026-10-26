import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart' show immutable;
import 'package:organista/services/connectivity/connectivity_service.dart';

part 'connectivity_state.dart';

/// Exposes the network state from [ConnectivityService] to widgets. Blocs and cubits read the service directly.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit({required ConnectivityService connectivityService})
    : super(ConnectivityState(isOnline: connectivityService.isOnline)) {
    _subscription = connectivityService.onlineChanges.listen((isOnline) => emit(ConnectivityState(isOnline: isOnline)));
  }

  StreamSubscription<bool>? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
