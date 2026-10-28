import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Local notifications initialization warning: $e');
    }
  }

  /// Show SafeWalk timer expiry reminder notification
  Future<void> showTimerExpiryNotification({
    required String destination,
    required int gracePeriodSeconds,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'safewalk_timer_channel',
        'SafeWalk Timer Alerts',
        channelDescription: 'Alerts when your safe walk countdown timer completes',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        1001,
        'SafeWalk Timer Reached Destination!',
        'You have $gracePeriodSeconds seconds to confirm you arrived at $destination safely.',
        notificationDetails,
        payload: 'timer_expiry',
      );
    } catch (e) {
      debugPrint('Error showing timer notification: $e');
    }
  }

  /// Cancel existing notification
  Future<void> cancelNotifications() async {
    try {
      await _notificationsPlugin.cancel(1001);
    } catch (_) {}
  }
}
