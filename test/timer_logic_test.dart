import 'package:flutter_test/flutter_test.dart';
import 'package:safewalk/models/emergency_contact.dart';
import 'package:safewalk/models/offline_alert.dart';
import 'package:safewalk/utils/app_constants.dart';

void main() {
  group('SafeWalk Timer & Escalation Logic Tests', () {
    String formatTime(int seconds) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    test('Countdown timer seconds format correctly to MM:SS', () {
      expect(formatTime(0), '00:00');
      expect(formatTime(9), '00:09');
      expect(formatTime(60), '01:00');
      expect(formatTime(65), '01:05');
      expect(formatTime(900), '15:00'); // 15 minutes default
      expect(formatTime(1800), '30:00'); // 30 minutes
    });

    test('OfflineAlert serializes and deserializes accurately with location coordinates', () {
      final now = DateTime(2026, 10, 21, 20, 0, 0);
      final alert = OfflineAlert(
        id: 'alert_12345',
        userId: 'usr_abc',
        userName: 'Tanaya',
        alertType: 'SAFE_WALK_TIMEOUT',
        destination: 'Hostel Block B',
        latitude: 28.5355,
        longitude: 77.3910,
        timestamp: now,
        isSynced: false,
      );

      final json = alert.toJson();
      expect(json['id'], 'alert_12345');
      expect(json['latitude'], 28.5355);
      expect(json['longitude'], 77.3910);
      expect(json['isSynced'], false);

      final revived = OfflineAlert.fromJson(json);
      expect(revived.id, alert.id);
      expect(revived.destination, 'Hostel Block B');
      expect(revived.latitude, alert.latitude);
      expect(revived.longitude, alert.longitude);
      expect(revived.isSynced, false);
    });

    test('EmergencyContact serialization preserves primary contact flag', () {
      final contact = EmergencyContact(
        id: 'c1',
        name: 'Mother',
        phoneNumber: '+919876543210',
        relationship: 'Parent',
        isPrimary: true,
        createdAt: DateTime.now(),
      );

      final json = contact.toJson();
      expect(json['isPrimary'], true);
      expect(json['relationship'], 'Parent');

      final revived = EmergencyContact.fromJson(json);
      expect(revived.isPrimary, true);
      expect(revived.name, 'Mother');
    });

    test('SMS template generator produces valid Google Maps coordinates link', () {
      final sms = AppConstants.buildSmsMessage(
        userName: 'Priya',
        reason: 'SAFE WALK TIMEOUT',
        latitude: 19.0760,
        longitude: 72.8777,
      );

      expect(sms, contains('Priya'));
      expect(sms, contains('SAFE WALK TIMEOUT'));
      expect(sms, contains('https://maps.google.com/?q=19.076,72.8777'));
      expect(sms, contains('Please check on me immediately'));
    });
  });
}
