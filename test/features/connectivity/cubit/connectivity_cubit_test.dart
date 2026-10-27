import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/connectivity/cubit/connectivity_cubit.dart';
import 'package:organista/services/connectivity/connectivity_service.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockConnectivityService service;
  late StreamController<bool> changes;

  setUp(() {
    service = MockConnectivityService();
    changes = StreamController<bool>.broadcast();
    when(() => service.isOnline).thenReturn(true);
    when(() => service.onlineChanges).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  test('starts from the current state of the service', () {
    when(() => service.isOnline).thenReturn(false);

    expect(ConnectivityCubit(connectivityService: service).state, const ConnectivityState(isOnline: false));
  });

  blocTest<ConnectivityCubit, ConnectivityState>(
    'mirrors every change reported by the service',
    build: () => ConnectivityCubit(connectivityService: service),
    act: (_) {
      changes.add(false);
      changes.add(true);
    },
    expect: () => const [ConnectivityState(isOnline: false), ConnectivityState(isOnline: true)],
  );
}
