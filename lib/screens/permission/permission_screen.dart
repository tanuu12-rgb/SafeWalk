import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Required'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppConstants.warningOrange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  color: AppConstants.warningOrange,
                  size: 54,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Location Access Needed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textLight,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'SafeWalk requires foreground location access to record your coordinates during walks and send precise GPS coordinates in SMS alerts to your emergency contacts.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppConstants.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.glassCardDecoration(
                  borderColor: AppConstants.warningOrange.withOpacity(0.4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppConstants.warningOrange, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Lab Note: Only foreground location is queried when an alert triggers. No background tracking is performed.',
                        style: TextStyle(fontSize: 12, color: AppConstants.textLight),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Open App Settings'),
                onPressed: () async {
                  await openAppSettings();
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
