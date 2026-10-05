import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:organista/managers/stream_manager.dart';

void main() {
  group('StreamManager.cancelStream', () {
    tearDown(() async {
      await StreamManager.instance.cancelAllStreams();
    });

    test('cancels the Firestore subscription and drops the cached value of that stream only', () async {
      var cancelled = false;
      final source = StreamController<int>(onCancel: () => cancelled = true);
      final otherSource = StreamController<int>();
      const identifier = 'test_cancel_stream';
      const otherIdentifier = 'test_other_stream';

      final subscription = StreamManager.instance
          .getBroadcastStream<int>(identifier, () => source.stream)
          .listen((_) {});
      final otherSubscription = StreamManager.instance
          .getBroadcastStream<int>(otherIdentifier, () => otherSource.stream)
          .listen((_) {});
      source.add(1);
      otherSource.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(StreamManager.instance.getStats()['cachedIdentifiers'], contains(identifier));

      await StreamManager.instance.cancelStream(identifier);

      final stats = StreamManager.instance.getStats();
      expect(cancelled, isTrue);
      expect(stats['streamIdentifiers'], isNot(contains(identifier)));
      expect(stats['cachedIdentifiers'], isNot(contains(identifier)));
      expect(stats['streamIdentifiers'], contains(otherIdentifier));
      expect(stats['cachedIdentifiers'], contains(otherIdentifier));

      await subscription.cancel();
      await otherSubscription.cancel();
      await source.close();
      await otherSource.close();
    });

    test('is a no-op for an identifier that has no stream', () async {
      await expectLater(StreamManager.instance.cancelStream('test_unknown_stream'), completes);
    });
  });
}
