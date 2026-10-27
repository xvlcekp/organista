import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/services/connectivity/connectivity_service.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> changes;
  late ConnectivityService service;

  setUp(() {
    connectivity = MockConnectivity();
    changes = StreamController<List<ConnectivityResult>>.broadcast();
    when(() => connectivity.onConnectivityChanged).thenAnswer((_) => changes.stream);
    when(() => connectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.wifi]);
    service = ConnectivityService(connectivity: connectivity);
  });

  tearDown(() async {
    await service.dispose();
    await changes.close();
  });

  test('is optimistic before start so that nothing is blocked while the app starts', () {
    expect(service.isOnline, isTrue);
  });

  test('start reads the current state', () async {
    when(() => connectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.none]);

    await service.start();

    expect(service.isOnline, isFalse);
  });

  test('follows the changes and reports each transition once', () async {
    await service.start();
    final emitted = <bool>[];
    final subscription = service.onlineChanges.listen(emitted.add);

    changes.add([ConnectivityResult.none]);
    changes.add([ConnectivityResult.none]);
    changes.add([ConnectivityResult.mobile]);
    changes.add([ConnectivityResult.wifi, ConnectivityResult.vpn]);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(emitted, [false, true]);
    expect(service.isOnline, isTrue);
  });
}
