import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:organista/logger/custom_logger.dart';

/// A singleton service to manage Firebase streams with caching
/// Streams are closed when not needed but last values are cached
/// for immediate display when returning to pages
class StreamManager {
  StreamManager._();
  static final StreamManager _instance = StreamManager._();
  static StreamManager get instance => _instance;

  final Map<String, _CachedStreamController> _streamControllers = {};
  final Map<String, dynamic> _cachedValues = {};
  final List<StreamSubscription> _allSubscriptions = [];

  /// Get a stream for a specific resource
  /// Returns cached value immediately if available, then starts real stream
  Stream<T> getBroadcastStream<T>(
    String identifier,
    Stream<T> Function() createFirestoreStream,
  ) {
    // Only log in debug mode to reduce overhead
    if (kDebugMode) {
      logger.d('Getting stream for: $identifier');
    }

    // Create a new stream controller for this request
    bool listenerAdded = false;
    StreamSubscription<T>? subscription;
    final controllerRef = <StreamController<T>>[];

    final controller = StreamController<T>(
      onListen: () {
        final controller = controllerRef[0];

        // Immediately provide cached value if available
        if (_cachedValues.containsKey(identifier)) {
          final cachedValue = _cachedValues[identifier] as T;
          if (kDebugMode) {
            logger.d('Providing cached value for: $identifier');
          }
          controller.add(cachedValue);
        }

        // Start or reuse the underlying Firestore stream
        _ensureStreamExists<T>(identifier, createFirestoreStream);

        // Subscribe to the underlying stream and increment listener count
        final streamController = _streamControllers[identifier]! as _CachedStreamController<T>;
        if (!listenerAdded) {
          streamController.listenerCount++;
          listenerAdded = true;
          if (kDebugMode) {
            logger.d('Listener added to $identifier. Total: ${streamController.listenerCount}');
          }
        }

        subscription = streamController.controller.stream.listen(
          (data) {
            if (!controller.isClosed) {
              controller.add(data);
            }
          },
          onError: (error) {
            if (!controller.isClosed) {
              controller.addError(error);
            }
          },
          onDone: () {
            if (!controller.isClosed) {
              controller.close();
            }
          },
        );

        // Clean up when this controller is canceled
        controller.onCancel = () {
          subscription?.cancel();
          // Only remove listener if we added one
          if (listenerAdded) {
            _removeListenerInternal(identifier);
            listenerAdded = false;
          }
        };
      },
    );

    controllerRef.add(controller);

    return controller.stream;
  }

  /// Ensure the underlying Firestore stream exists
  void _ensureStreamExists<T>(String identifier, Stream<T> Function() createFirestoreStream) {
    if (!_streamControllers.containsKey(identifier)) {
      if (kDebugMode) {
        logger.d('Creating new Firestore stream for: $identifier');
      }

      final controller = StreamController<T>.broadcast();
      final subscriptionRef = <StreamSubscription<T>>[];

      // Create the underlying Firestore stream
      final firestoreSubscription = createFirestoreStream().listen(
        (data) {
          _cachedValues[identifier] = data; // Cache the value
          if (!controller.isClosed) {
            controller.add(data);
          }
        },
        onError: (error, stackTrace) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
          logger.e('Error in stream $identifier', error: error, stackTrace: stackTrace);
        },
        onDone: () {
          if (kDebugMode) {
            logger.d('Firestore stream completed for: $identifier');
          }
          if (!controller.isClosed) {
            controller.close();
          }
          _streamControllers.remove(identifier);
          _allSubscriptions.remove(subscriptionRef[0]);
        },
      );

      subscriptionRef.add(firestoreSubscription);

      // Store the controller and subscription
      _streamControllers[identifier] = _CachedStreamController<T>(
        controller: controller,
        firestoreSubscription: firestoreSubscription,
        listenerCount: 0,
      );
      _allSubscriptions.add(firestoreSubscription);
    }
  }

  /// Internal method to remove listener with proper safeguards
  void _removeListenerInternal(String identifier) {
    final streamController = _streamControllers[identifier];
    if (streamController != null && streamController.listenerCount > 0) {
      streamController.listenerCount--;
      if (kDebugMode) {
        logger.d('Listener removed from $identifier. Remaining: ${streamController.listenerCount}');
      }

      // If no more listeners, schedule cleanup (but keep cached value)
      if (streamController.listenerCount <= 0) {
        Timer(const Duration(seconds: 2), () {
          if (streamController.listenerCount <= 0 && _streamControllers.containsKey(identifier)) {
            if (kDebugMode) {
              logger.d('Cleaning up unused stream: $identifier (keeping cached value)');
            }
            _cleanupStream(identifier);
          }
        });
      }
    } else if (streamController != null) {
      if (kDebugMode) {
        logger.w(
          'Attempted to remove listener from $identifier but count is already ${streamController.listenerCount}',
        );
      }
    }
  }

  /// Public method for BLoCs to remove listeners (with safeguards)
  void removeListener(String identifier) {
    _removeListenerInternal(identifier);
  }

  /// Clean up a specific stream but keep cached value
  void _cleanupStream(String identifier) {
    final streamController = _streamControllers[identifier];
    if (streamController != null) {
      streamController.firestoreSubscription.cancel();
      if (!streamController.controller.isClosed) {
        streamController.controller.close();
      }
      _streamControllers.remove(identifier);
      _allSubscriptions.remove(streamController.firestoreSubscription);
      // Note: We keep the cached value in _cachedValues for future use
    }
  }

  /// Cancel all streams and clear cache (called on logout)
  Future<void> cancelAllStreams() async {
    logger.i('Canceling all Firebase streams (${_allSubscriptions.length} active) and clearing cache');

    // Cancel all Firestore subscriptions
    final futures = _allSubscriptions.map((sub) => sub.cancel());
    await Future.wait(futures);

    // Close all stream controllers
    for (final streamController in _streamControllers.values) {
      if (!streamController.controller.isClosed) {
        await streamController.controller.close();
      }
    }

    _streamControllers.clear();
    _allSubscriptions.clear();
    _cachedValues.clear(); // Clear cached values on logout
    logger.i('All Firebase streams have been canceled and cache cleared');
  }

  /// Get statistics about active streams and cache
  Map<String, dynamic> getStats() {
    return {
      'activeStreams': _allSubscriptions.length,
      'streamControllers': _streamControllers.length,
      'cachedValues': _cachedValues.length,
      'streamIdentifiers': _streamControllers.keys.toList(),
      'cachedIdentifiers': _cachedValues.keys.toList(),
      'listenerCounts': _streamControllers.map(
        (key, value) => MapEntry(key, value.listenerCount),
      ),
    };
  }
}

/// Internal class to manage stream controller state
class _CachedStreamController<T> {
  final StreamController<T> controller;
  final StreamSubscription firestoreSubscription;
  int listenerCount;

  _CachedStreamController({
    required this.controller,
    required this.firestoreSubscription,
    required this.listenerCount,
  });
}
