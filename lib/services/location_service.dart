import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_routes.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final bool isDefaultFallback;
  final String? errorMessage;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.isDefaultFallback = false,
    this.errorMessage,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Checks location permissions and returns Position or null if denied
  Future<LocationResult> getCurrentForegroundLocation(BuildContext? context) async {
    try {
      // 1. Check if location services are enabled on device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          latitude: 28.6139,
          longitude: 77.2090, // Delhi fallback coordinates for demo
          isDefaultFallback: true,
          errorMessage: 'Location services are disabled on device.',
        );
      }

      // 2. Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context != null && context.mounted) {
            Navigator.pushNamed(context, AppRoutes.permission);
          }
          return const LocationResult(
            latitude: 28.6139,
            longitude: 77.2090,
            isDefaultFallback: true,
            errorMessage: 'Location permission denied by user.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context != null && context.mounted) {
          Navigator.pushNamed(context, AppRoutes.permission);
        }
        return const LocationResult(
          latitude: 28.6139,
          longitude: 77.2090,
          isDefaultFallback: true,
          errorMessage: 'Location permission permanently denied.',
        );
      }

      // 3. Fetch current foreground position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        isDefaultFallback: false,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Graceful fallback for emulator or poor GPS lock
      return LocationResult(
        latitude: 28.6139,
        longitude: 77.2090,
        isDefaultFallback: true,
        errorMessage: 'GPS lock timeout. Default coordinate used: $e',
      );
    }
  }

  /// Direct permission status check
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }
}
