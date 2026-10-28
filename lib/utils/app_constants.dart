import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'SafeWalk';
  static const String appTagline = 'Your Personal Guardian on Every Journey';

  // Local storage JSON filenames
  static const String contactsFileName = 'safewalk_emergency_contacts.json';
  static const String offlineAlertsFileName = 'safewalk_offline_alerts.json';
  static const String walkHistoryFileName = 'safewalk_history.json';
  static const String unsafeReportsFileName = 'safewalk_unsafe_reports.json';

  // Firebase Realtime Database
  static const String databaseUrl =
      'https://safewalk-857eb-default-rtdb.asia-southeast1.firebasedatabase.app';
  static const String dbUsers = 'users';
  static const String dbContacts = 'contacts';
  static const String dbAlerts = 'alerts';
  static const String dbSafeWalks = 'safewalks';
  static const String dbReports = 'unsafe_reports';

  // Safe Walk Timer defaults
  static const int defaultGracePeriodSeconds = 60;
  static const int shakeThreshold = 18; // m/s^2 acceleration spike

  // Unsafe Area Categories for Dropdown & Chart
  static const List<String> unsafeCategories = [
    'Poor Lighting / Dark Street',
    'Deserted Alley / Isolated Path',
    'Suspicious Activity / Harassment',
    'No Security / Lack of Help',
    'Other Hazard',
  ];

  // Color Palette - Tailored for Safety Prototypes
  static const Color primaryViolet = Color(0xFF6366F1); // Modern Indigo/Violet
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFF818CF8);

  static const Color emergencyRed = Color(0xFFE11D48); // High-contrast Red for SOS
  static const Color emergencyRedGlow = Color(0xFFFDA4AF);

  static const Color safeGreen = Color(0xFF10B981); // Emerald Green for "Safe"
  static const Color warningOrange = Color(0xFFF59E0B); // Amber warning

  static const Color bgDark = Color(0xFF0F172A); // Deep Slate Navy
  static const Color bgCard = Color(0xFF1E293B); // Dark Surface
  static const Color bgCardLight = Color(0xFF334155);

  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  // SMS Pre-filled Template Generator
  static String buildSmsMessage({
    required String userName,
    required String reason,
    required double latitude,
    required double longitude,
  }) {
    final mapUrl = 'https://maps.google.com/?q=$latitude,$longitude';
    return 'EMERGENCY ALERT from $userName via SafeWalk App!\n'
        'Alert Reason: $reason\n'
        'Last Known Location: $mapUrl\n'
        '(Coordinates: $latitude, $longitude)\n'
        'Please check on me immediately.';
  }
}
