import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/emergency_contact.dart';
import '../models/offline_alert.dart';
import '../models/unsafe_report.dart';
import '../utils/app_constants.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  /// Gets the local app documents directory path
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Reference to contacts JSON file
  Future<File> get _contactsFile async {
    final path = await _localPath;
    return File('$path/${AppConstants.contactsFileName}');
  }

  /// Reference to offline alerts JSON file
  Future<File> get _offlineAlertsFile async {
    final path = await _localPath;
    return File('$path/${AppConstants.offlineAlertsFileName}');
  }

  /// Reference to unsafe reports JSON file
  Future<File> get _unsafeReportsFile async {
    final path = await _localPath;
    return File('$path/${AppConstants.unsafeReportsFileName}');
  }

  // ==========================================
  // EMERGENCY CONTACTS FILE HANDLING
  // ==========================================

  /// Load contacts from JSON file. Returns empty list or seeded contacts if new.
  Future<List<EmergencyContact>> loadContacts() async {
    try {
      final file = await _contactsFile;
      if (!await file.exists()) {
        // Seed default starter contacts for initial run / evaluation
        final defaultContacts = [
          EmergencyContact(
            id: 'sample-1',
            name: 'Mom / Guardian',
            phoneNumber: '+15550199',
            relationship: 'Parent',
            isPrimary: true,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          EmergencyContact(
            id: 'sample-2',
            name: 'Campus Security',
            phoneNumber: '+15550112',
            relationship: 'Guardian',
            isPrimary: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 12)),
          ),
        ];
        await saveContacts(defaultContacts);
        return defaultContacts;
      }

      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(contents);
      return decoded.map((item) => EmergencyContact.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e, stack) {
      debugPrint('Error loading emergency contacts from local JSON file: $e\n$stack');
      return [];
    }
  }

  /// Save contacts list to JSON file
  Future<bool> saveContacts(List<EmergencyContact> contacts) async {
    try {
      final file = await _contactsFile;
      final jsonString = jsonEncode(contacts.map((c) => c.toJson()).toList());
      await file.writeAsString(jsonString, flush: true);
      return true;
    } catch (e, stack) {
      debugPrint('Error saving emergency contacts to local JSON file: $e\n$stack');
      return false;
    }
  }

  /// Add or update a single contact
  Future<bool> saveContact(EmergencyContact contact) async {
    final current = await loadContacts();
    final index = current.indexWhere((c) => c.id == contact.id);

    // If marked primary, ensure other contacts are un-marked
    List<EmergencyContact> updated = current.map((c) {
      if (contact.isPrimary && c.id != contact.id) {
        return c.copyWith(isPrimary: false);
      }
      return c;
    }).toList();

    if (index >= 0) {
      updated[index] = contact;
    } else {
      updated.add(contact);
    }
    return await saveContacts(updated);
  }

  /// Delete a contact by ID
  Future<bool> deleteContact(String id) async {
    final current = await loadContacts();
    current.removeWhere((c) => c.id == id);
    return await saveContacts(current);
  }

  // ==========================================
  // OFFLINE ALERTS LOG FILE HANDLING
  // ==========================================

  /// Load all offline alerts recorded in local JSON
  Future<List<OfflineAlert>> loadOfflineAlerts() async {
    try {
      final file = await _offlineAlertsFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(contents);
      return decoded.map((item) => OfflineAlert.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e, stack) {
      debugPrint('Error loading offline alerts from local file: $e\n$stack');
      return [];
    }
  }

  /// Record a new alert into local JSON log
  Future<bool> recordAlert(OfflineAlert alert) async {
    try {
      final alerts = await loadOfflineAlerts();
      alerts.insert(0, alert); // Newest first
      final file = await _offlineAlertsFile;
      final jsonString = jsonEncode(alerts.map((a) => a.toJson()).toList());
      await file.writeAsString(jsonString, flush: true);
      return true;
    } catch (e) {
      debugPrint('Error writing alert to local JSON: $e');
      return false;
    }
  }

  /// Mark an offline alert as synced
  Future<void> markAlertSynced(String alertId) async {
    try {
      final alerts = await loadOfflineAlerts();
      final index = alerts.indexWhere((a) => a.id == alertId);
      if (index >= 0) {
        alerts[index] = alerts[index].copyWith(isSynced: true, syncError: null);
        final file = await _offlineAlertsFile;
        await file.writeAsString(jsonEncode(alerts.map((a) => a.toJson()).toList()), flush: true);
      }
    } catch (e) {
      debugPrint('Error updating alert sync status in local JSON: $e');
    }
  }

  // ==========================================
  // UNSAFE REPORTS LOCAL JSON PERSISTENCE
  // ==========================================

  /// Load locally saved unsafe reports
  Future<List<UnsafeReport>> loadUnsafeReports() async {
    try {
      final file = await _unsafeReportsFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(contents);
      return decoded.map((item) => UnsafeReport.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading unsafe reports from local file: $e');
      return [];
    }
  }

  /// Save an unsafe report to local JSON file
  Future<bool> saveUnsafeReport(UnsafeReport report) async {
    try {
      final reports = await loadUnsafeReports();
      reports.insert(0, report);
      final file = await _unsafeReportsFile;
      final jsonString = jsonEncode(reports.map((r) => r.toJson()).toList());
      await file.writeAsString(jsonString, flush: true);
      return true;
    } catch (e) {
      debugPrint('Error saving unsafe report to local JSON: $e');
      return false;
    }
  }
}

