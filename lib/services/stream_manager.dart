import 'dart:async';
import 'package:organista/logger/custom_logger.dart';

/// A singleton service to manage Firebase streams with proper broadcasting
/// This ensures streams can be reused by multiple BLoCs without conflicts
/// and new listeners immediately receive the last known value
class StreamManager {
  StreamManager._();
  static final StreamManager _instance = StreamManager._();
  static StreamManager get instance => _instance;

  final Map<String, _BroadcastStreamController> _streamControllers = {};
  final List<StreamSubscription> _allSubscriptions = [];

  /// Get a broadcast stream for a specific resource
  /// Multiple BLoCs can listen to the same underlying Firestore stream
  /// New listeners immediately receive the last known value
  Stream<T> getBroadcastStream<T>(
    String identifier,
    Stream<T> Function() createFirestoreStream,
  ) {
    // Get or create stream controller for this identifier
    if (!_streamControllers.containsKey(identifier)) {
      logger.d('Creating new broadcast stream for: $identifier');

      final controller = StreamController<T>.broadcast();
      late StreamSubscription firestoreSubscription;
      T? lastValue;

      // Create the underlying Firestore stream
      firestoreSubscription = createFirestoreStream().listen(
        (data) {
          lastValue = data; // Store the last value
          if (!controller.isClosed) {
            controller.add(data);
          }
        },
        onError: (error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
          logger.e('Error in broadcast stream $identifier: $error');
        },
        onDone: () {
          logger.d('Firestore stream completed for: $identifier');
          if (!controller.isClosed) {
            controller.close();
          }
          _streamControllers.remove(identifier);
          _allSubscriptions.remove(firestoreSubscription);
        },
      );

      // Store the controller and subscription
      _streamControllers[identifier] = _BroadcastStreamController<T>(
        controller: controller,
        firestoreSubscription: firestoreSubscription,
        listenerCount: 0,
        lastValue: () => lastValue,
      );
      _allSubscriptions.add(firestoreSubscription);
    } else {
      logger.d('Reusing existing broadcast stream for: $identifier');
    }

    final streamController = _streamControllers[identifier]! as _BroadcastStreamController<T>;
    streamController.listenerCount++;

    logger.d('Active listeners for $identifier: ${streamController.listenerCount}');

    // Create a stream that immediately provides the last value (if any) and then forwards future events
    late StreamController<T> personalController;
    personalController = StreamController<T>(
      onListen: () {
        // Immediately provide the last value if available
        final lastValue = streamController.lastValue();
        if (lastValue != null) {
          logger.d('Providing last value to new listener for: $identifier');
          personalController.add(lastValue);
        }
      },
    );

    // Forward all future events from the broadcast stream
    late StreamSubscription broadcastSubscription;
    broadcastSubscription = streamController.controller.stream.listen(
      (data) {
        if (!personalController.isClosed) {
          personalController.add(data);
        }
      },
      onError: (error) {
        if (!personalController.isClosed) {
          personalController.addError(error);
        }
      },
      onDone: () {
        if (!personalController.isClosed) {
          personalController.close();
        }
      },
    );

    // Clean up when the personal stream is canceled
    personalController.onCancel = () {
      broadcastSubscription.cancel();
    };

    return personalController.stream;
  }

  /// Notify that a listener has stopped listening to a stream
  void removeListener(String identifier) {
    final streamController = _streamControllers[identifier];
    if (streamController != null) {
      streamController.listenerCount--;
      logger.d('Listener removed from $identifier. Remaining: ${streamController.listenerCount}');

      // If no more listeners, schedule cleanup
      if (streamController.listenerCount <= 0) {
        Timer(const Duration(seconds: 5), () {
          if (streamController.listenerCount <= 0 && _streamControllers.containsKey(identifier)) {
            logger.d('Cleaning up unused stream: $identifier');
            _cleanupStream(identifier);
          }
        });
      }
    }
  }

  /// Clean up a specific stream
  void _cleanupStream(String identifier) {
    final streamController = _streamControllers[identifier];
    if (streamController != null) {
      streamController.firestoreSubscription.cancel();
      if (!streamController.controller.isClosed) {
        streamController.controller.close();
      }
      _streamControllers.remove(identifier);
      _allSubscriptions.remove(streamController.firestoreSubscription);
    }
  }

  /// Cancel all streams (called on logout)
  Future<void> cancelAllStreams() async {
    logger.i('Canceling all Firebase streams (${_allSubscriptions.length} active)');

    // Cancel all Firestore subscriptions
    final futures = _allSubscriptions.map((sub) => sub.cancel());
    await Future.wait(futures);

    // Close all stream controllers
    for (final streamController in _streamControllers.values) {
      if (!streamController.controller.isClosed) {
        streamController.controller.close();
      }
    }

    _streamControllers.clear();
    _allSubscriptions.clear();
    logger.i('All Firebase streams have been canceled');
  }

  /// Get statistics about active streams
  Map<String, dynamic> getStats() {
    return {
      'activeStreams': _allSubscriptions.length,
      'broadcastStreams': _streamControllers.length,
      'streamIdentifiers': _streamControllers.keys.toList(),
      'listenerCounts': _streamControllers.map(
        (key, value) => MapEntry(key, value.listenerCount),
      ),
    };
  }
}

/// Internal class to manage stream controller state
class _BroadcastStreamController<T> {
  final StreamController<T> controller;
  final StreamSubscription firestoreSubscription;
  final T? Function() lastValue;
  int listenerCount;

  _BroadcastStreamController({
    required this.controller,
    required this.firestoreSubscription,
    required this.lastValue,
    required this.listenerCount,
  });
}
