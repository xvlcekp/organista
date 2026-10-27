import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Single source of the device's network state: [isOnline] is the last known value and [onlineChanges] reports
/// every change. A network does not guarantee that Firebase is reachable, so callers still handle failed requests;
/// this only decides whether a request is worth starting and how a failure is explained.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _changes = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Optimistic until the first check so that nothing is blocked while the app starts.
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Stream<bool> get onlineChanges => _changes.stream;

  /// Reads the current state and keeps following it.
  Future<void> start() async {
    _subscription = _connectivity.onConnectivityChanged.listen((results) => _update(_hasNetwork(results)));
    _update(_hasNetwork(await _connectivity.checkConnectivity()));
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _changes.close();
  }

  void _update(bool isOnline) {
    if (isOnline == _isOnline) return;
    _isOnline = isOnline;
    _changes.add(isOnline);
  }

  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
