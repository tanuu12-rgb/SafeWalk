import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact.dart';
import '../models/offline_alert.dart';
import '../utils/app_constants.dart';
import 'auth_service.dart';
import 'firebase_db_service.dart';
import 'local_storage_service.dart';
import 'location_service.dart';

class EscalationResult {
  final bool success;
  final bool isCloudSynced;
  final double latitude;
  final double longitude;
  final List<EmergencyContact> contactsNotified;
  final String? errorMessage;

  const EscalationResult({
    required this.success,
    required this.isCloudSynced,
    required this.latitude,
    required this.longitude,
    required this.contactsNotified,
    this.errorMessage,
  });
}

class EscalationService {
  static final EscalationService _instance = EscalationService._internal();
  factory EscalationService() => _instance;
  EscalationService._internal();

  final _locationService = LocationService();
  final _storageService = LocalStorageService();
  final _dbService = FirebaseDbService();
  final _authService = AuthService();

  /// Executes full emergency escalation workflow
  Future<EscalationResult> executeEscalation({
    required BuildContext? context,
    required String alertType, // 'SAFE_WALK_TIMEOUT', 'MANUAL_SOS', 'SHAKE_SOS'
    required String destination,
  }) async {
    try {
      // 1. Get current foreground location
      final location = await _locationService.getCurrentForegroundLocation(context);

      // 2. Load emergency contacts
      final contacts = await _storageService.loadContacts();
      final user = _authService.currentUser;
      final userName = user?.displayName ?? 'SafeWalk User';
      final userId = user?.uid ?? 'local_user';

      // 3. Create alert entity
      final alert = OfflineAlert(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        alertType: alertType,
        destination: destination,
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: DateTime.now(),
      );

      // 4. Save alert to Firebase (with offline fallback to local JSON)
      final bool cloudSynced = await _dbService.recordAlert(alert);

      // 5. Open pre-filled SMS via url_launcher to primary or all contacts
      if (contacts.isNotEmpty) {
        final primaryContact = contacts.firstWhere(
          (c) => c.isPrimary,
          orElse: () => contacts.first,
        );

        final smsBody = AppConstants.buildSmsMessage(
          userName: userName,
          reason: alertType.replaceAll('_', ' '),
          latitude: location.latitude,
          longitude: location.longitude,
        );

        await launchSms(
          phoneNumber: primaryContact.phoneNumber,
          message: smsBody,
        );
      }

      return EscalationResult(
        success: true,
        isCloudSynced: cloudSynced,
        latitude: location.latitude,
        longitude: location.longitude,
        contactsNotified: contacts,
      );
    } catch (e) {
      debugPrint('Error executing escalation: $e');
      return EscalationResult(
        success: false,
        isCloudSynced: false,
        latitude: 0,
        longitude: 0,
        contactsNotified: [],
        errorMessage: e.toString(),
      );
    }
  }

  /// Launch pre-filled SMS client via url_launcher
  /// Lab Note: The user MUST tap send in their messaging app (no silent background SMS)
  Future<bool> launchSms({
    required String phoneNumber,
    required String message,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        // Fallback for some Android OEM intents
        final fallbackUri = Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(message)}');
        return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch SMS url: $e');
      return false;
    }
  }
}
