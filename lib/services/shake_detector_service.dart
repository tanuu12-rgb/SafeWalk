import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetectorService {
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  final VoidCallback onShake;
  final double threshold;
  final Duration debounceDuration;

  DateTime _lastShakeTime = DateTime.now().subtract(const Duration(seconds: 5));
  bool _isListening = false;

  ShakeDetectorService({
    required this.onShake,
    this.threshold = 18.0,
    this.debounceDuration = const Duration(milliseconds: 1500),
  });

  /// Starts listening to phone shake via accelerometer
  void startListening() {
    if (_isListening) return;

    try {
      _subscription = userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          final double magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          if (magnitude > threshold) {
            final now = DateTime.now();
            if (now.difference(_lastShakeTime) > debounceDuration) {
              _lastShakeTime = now;
              debugPrint('Shake gesture detected! Magnitude: $magnitude');
              onShake();
            }
          }
        },
        onError: (error) {
          debugPrint('Shake detection sensor error: $error');
        },
        cancelOnError: false,
      );
      _isListening = true;
    } catch (e) {
      debugPrint('Could not initialize accelerometer sensor: $e');
    }
  }

  /// Stops listening to accelerometer events to save battery
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }
}
