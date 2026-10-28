import 'package:flutter/material.dart';
import '../../models/unsafe_report.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_db_service.dart';
import '../../services/location_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class ReportUnsafeScreen extends StatefulWidget {
  const ReportUnsafeScreen({super.key});

  @override
  State<ReportUnsafeScreen> createState() => _ReportUnsafeScreenState();
}

class _ReportUnsafeScreenState extends State<ReportUnsafeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationService = LocationService();
  final _dbService = FirebaseDbService();
  final _authService = AuthService();

  String _selectedCategory = AppConstants.unsafeCategories.first;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    final loc = await _locationService.getCurrentForegroundLocation(context);
    if (mounted) {
      setState(() {
        _latitude = loc.latitude;
        _longitude = loc.longitude;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for GPS coordinates to be acquired.'),
          backgroundColor: AppConstants.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = _authService.currentUser;
    final report = UnsafeReport(
      id: 'report_${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.uid ?? 'anonymous_user',
      userEmail: user?.email ?? 'Anonymous User',
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      latitude: _latitude!,
      longitude: _longitude!,
      timestamp: DateTime.now(),
    );

    final success = await _dbService.recordUnsafeReport(report);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppConstants.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppConstants.safeGreen, size: 28),
                SizedBox(width: 8),
                Text('Report Submitted', style: TextStyle(color: AppConstants.textLight)),
              ],
            ),
            content: const Text(
              'Your report has been saved locally and queued for Firebase Realtime Database sync. It is now reflected in your analytics chart.',
              style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Back to Home'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacementNamed(context, AppRoutes.activityStats);
                },
                child: const Text('View Chart'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not write to Firebase. Check internet or google-services.json.'),
            backgroundColor: AppConstants.emergencyRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Unsafe Area'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCardDecoration(
                    borderColor: AppConstants.warningOrange.withOpacity(0.4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppConstants.warningOrange.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_moon_outlined, color: AppConstants.warningOrange, size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crowdsourced Safety Map',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textLight,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Help other women stay aware. Reports are synchronized across users and feed the real-time analytics chart.',
                              style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Category Dropdown (Syllabus Requirement)
                const Text(
                  'Hazard Category',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textLight),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  dropdownColor: AppConstants.bgCard,
                  items: AppConstants.unsafeCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        style: const TextStyle(color: AppConstants.textLight, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 20),

                // Description TextFormField
                const Text(
                  'Description & Details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textLight),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Streetlights were completely broken between 9th and 10th block near the underpass...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 8) {
                      return 'Please provide a helpful description (at least 8 characters)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Location Coordinates Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: AppConstants.primaryLight, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Incident Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.textLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: _isLoadingLocation
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location, size: 16),
                            label: const Text('Refresh GPS', style: TextStyle(fontSize: 12)),
                            onPressed: _isLoadingLocation ? null : _fetchCurrentLocation,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _latitude != null && _longitude != null
                            ? 'Lat: ${_latitude!.toStringAsFixed(5)}, Lng: ${_longitude!.toStringAsFixed(5)}'
                            : 'Acquiring GPS coordinates...',
                        style: TextStyle(
                          fontSize: 13,
                          color: _latitude != null ? AppConstants.textLight : AppConstants.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Coordinates are automatically captured from your device GPS.',
                        style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Submit Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.warningOrange,
                      foregroundColor: Colors.black,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSubmitting ? 'Writing to Firebase...' : 'Submit Unsafe Area Report',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: _isSubmitting ? null : _submitReport,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
