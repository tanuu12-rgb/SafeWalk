import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/safe_walk_session.dart';
import '../../services/auth_service.dart';
import '../../services/escalation_service.dart';
import '../../services/firebase_db_service.dart';
import '../../services/notification_service.dart';
import '../../services/shake_detector_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

enum WalkState { setup, walking, gracePeriod, escalated, arrived }

class SafeWalkScreen extends StatefulWidget {
  const SafeWalkScreen({super.key});

  @override
  State<SafeWalkScreen> createState() => _SafeWalkScreenState();
}

class _SafeWalkScreenState extends State<SafeWalkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController(text: 'Home');
  final _escalationService = EscalationService();
  final _notificationService = NotificationService();
  final _dbService = FirebaseDbService();
  final _authService = AuthService();

  WalkState _walkState = WalkState.setup;
  int _selectedMinutes = 15;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  int _graceSecondsRemaining = AppConstants.defaultGracePeriodSeconds;

  Timer? _countdownTimer;
  Timer? _graceTimer;
  ShakeDetectorService? _shakeDetector;
  bool _isEscalating = false;

  final List<String> _quickDestinations = [
    'Home',
    'Hostel Room',
    'Metro Station',
    'Bus Stop',
    'Library / Lab',
  ];

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();

    // Start shake detector to catch shakes on this screen
    _shakeDetector = ShakeDetectorService(
      onShake: () {
        if (_walkState == WalkState.walking || _walkState == WalkState.gracePeriod) {
          _triggerImmediateEscalation('SHAKE_SOS');
        }
      },
    );
    _shakeDetector?.startListening();

    // Check if autoSos argument was passed from Home SOS button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['autoSos'] == true) {
        _triggerImmediateEscalation('MANUAL_SOS');
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _graceTimer?.cancel();
    _shakeDetector?.stopListening();
    _destinationController.dispose();
    super.dispose();
  }

  void _startWalk() {
    if (!_formKey.currentState!.validate()) return;

    final durationSec = _selectedMinutes * 60;
    setState(() {
      _walkState = WalkState.walking;
      _totalSeconds = durationSec;
      _remainingSeconds = durationSec;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _enterGracePeriod();
      }
    });
  }

  void _enterGracePeriod() {
    setState(() {
      _walkState = WalkState.gracePeriod;
      _graceSecondsRemaining = AppConstants.defaultGracePeriodSeconds;
    });

    // 1. Show local notification reminder
    _notificationService.showTimerExpiryNotification(
      destination: _destinationController.text.trim(),
      gracePeriodSeconds: AppConstants.defaultGracePeriodSeconds,
    );

    // 2. Start 60-second grace countdown
    _graceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_graceSecondsRemaining > 1) {
        setState(() => _graceSecondsRemaining--);
      } else {
        timer.cancel();
        // 3. Grace period ended without confirmation -> escalate automatically
        _triggerImmediateEscalation('SAFE_WALK_TIMEOUT');
      }
    });
  }

  Future<void> _confirmArrival() async {
    _countdownTimer?.cancel();
    _graceTimer?.cancel();
    _notificationService.cancelNotifications();

    final user = _authService.currentUser;
    final session = SafeWalkSession(
      id: 'walk_${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.uid ?? 'local_user',
      destination: _destinationController.text.trim(),
      durationMinutes: _selectedMinutes,
      startTime: DateTime.now().subtract(Duration(seconds: _totalSeconds - _remainingSeconds)),
      scheduledEndTime: DateTime.now(),
      status: 'ARRIVED_SAFELY',
    );

    await _dbService.recordSafeWalk(session);

    if (mounted) {
      setState(() => _walkState = WalkState.arrived);
    }
  }

  void _cancelWalk() {
    _countdownTimer?.cancel();
    _graceTimer?.cancel();
    _notificationService.cancelNotifications();
    setState(() => _walkState = WalkState.setup);
  }

  Future<void> _triggerImmediateEscalation(String alertType) async {
    _countdownTimer?.cancel();
    _graceTimer?.cancel();
    _notificationService.cancelNotifications();

    setState(() {
      _walkState = WalkState.escalated;
      _isEscalating = true;
    });

    final result = await _escalationService.executeEscalation(
      context: context,
      alertType: alertType,
      destination: _destinationController.text.trim(),
    );

    if (mounted) {
      setState(() => _isEscalating = false);
      _showEscalationSummaryDialog(result, alertType);
    }
  }

  void _showEscalationSummaryDialog(EscalationResult result, String alertType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.report_gmailerrorred_rounded, color: AppConstants.emergencyRed, size: 28),
            SizedBox(width: 8),
            Text('Alert Escalated', style: TextStyle(color: AppConstants.textLight)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason: ${alertType.replaceAll('_', ' ')}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textLight),
            ),
            const SizedBox(height: 8),
            Text(
              'GPS Coordinates: ${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
              style: const TextStyle(color: AppConstants.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              result.isCloudSynced
                  ? 'Status: Logged to Firebase Realtime Database & Local Storage.'
                  : 'Status: Logged to Local JSON Storage (Offline). Ready for retry.',
              style: TextStyle(
                color: result.isCloudSynced ? AppConstants.safeGreen : AppConstants.warningOrange,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppConstants.bgCardLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Note: Pre-filled SMS was launched in your messaging app. You must tap "Send" in SMS app to complete transmission.',
                style: TextStyle(fontSize: 11, color: AppConstants.textLight),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _walkState = WalkState.setup);
            },
            child: const Text('Return to Setup'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Walk Timer'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _buildCurrentStateView(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStateView() {
    switch (_walkState) {
      case WalkState.setup:
        return _buildSetupView();
      case WalkState.walking:
        return _buildWalkingView();
      case WalkState.gracePeriod:
        return _buildGracePeriodView();
      case WalkState.escalated:
        return _buildEscalatedView();
      case WalkState.arrived:
        return _buildArrivedView();
    }
  }

  /// 1. SETUP VIEW
  Widget _buildSetupView() {
    return SingleChildScrollView(
      key: const ValueKey('setup'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.glassCardDecoration(),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryViolet.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppConstants.primaryLight, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dead-Man's Switch",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textLight,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'If you do not confirm arrival before the timer ends, the app alerts contacts automatically.',
                          style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Destination Field
            const Text(
              'Destination',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConstants.textLight),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Where are you walking to?',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Destination is required';
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Quick destination chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _quickDestinations.map((dest) {
                return ActionChip(
                  label: Text(dest, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppConstants.bgCard,
                  onPressed: () {
                    setState(() => _destinationController.text = dest);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Walk Duration Selector
            const Text(
              'Estimated Walk Duration',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConstants.textLight),
            ),
            const SizedBox(height: 10),
            Row(
              children: [1, 5, 10, 15, 30].map((mins) {
                final isSelected = _selectedMinutes == mins;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: ChoiceChip(
                      label: Text('${mins}m'),
                      selected: isSelected,
                      selectedColor: AppConstants.primaryViolet,
                      backgroundColor: AppConstants.bgCard,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppConstants.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedMinutes = mins);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Selected: $_selectedMinutes minutes (Tip: use 1m to test timer in lab)',
              style: const TextStyle(fontSize: 12, color: AppConstants.primaryLight),
            ),
            const SizedBox(height: 32),

            // Start Button
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions_walk_rounded),
                label: const Text('Start Safe Walk Timer', style: TextStyle(fontSize: 16)),
                onPressed: _startWalk,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. WALKING COUNTDOWN VIEW
  Widget _buildWalkingView() {
    final progress = _totalSeconds > 0 ? (_remainingSeconds / _totalSeconds) : 0.0;

    return Center(
      key: const ValueKey('walking'),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Destination Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryViolet.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppConstants.primaryLight.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.navigation, color: AppConstants.primaryLight, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'En route to: ${_destinationController.text}',
                    style: const TextStyle(color: AppConstants.textLight, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Circular Countdown Display
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: AppConstants.bgCardLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryViolet),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: AppConstants.primaryLight, size: 30),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: AppConstants.textLight,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'REMAINING',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppConstants.textMuted,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Arrived Safely Button (Syllabus Requirement)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.safeGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 24),
                label: const Text(
                  "I've Arrived Safely",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _confirmArrival,
              ),
            ),
            const SizedBox(height: 14),

            // Cancel Walk Button
            OutlinedButton(
              onPressed: _cancelWalk,
              child: const Text('Cancel Walk'),
            ),
            const SizedBox(height: 18),

            // Shake helper
            const Text(
              'Phone shake detection active: vigorous shake triggers instant SOS',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. GRACE PERIOD ALARM VIEW
  Widget _buildGracePeriodView() {
    return Center(
      key: const ValueKey('grace'),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.emergencyRed.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppConstants.emergencyRed,
                size: 72,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'TIMER COMPLETED!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppConstants.emergencyRed,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Grace period running. Are you safe?',
              style: TextStyle(fontSize: 14, color: AppConstants.textLight),
            ),
            const SizedBox(height: 20),

            // Grace Countdown Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: AppConstants.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.emergencyRed, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    '$_graceSecondsRemaining',
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.emergencyRed,
                    ),
                  ),
                  const Text(
                    'SECONDS BEFORE AUTOMATIC ESCALATION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // I AM SAFE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.safeGreen),
                icon: const Icon(Icons.check),
                label: const Text("I Am Safe! (Cancel Alert)"),
                onPressed: _confirmArrival,
              ),
            ),
            const SizedBox(height: 12),

            // ESCALATE NOW BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.emergencyRed,
                  side: const BorderSide(color: AppConstants.emergencyRed),
                ),
                icon: const Icon(Icons.warning),
                label: const Text('Escalate Immediately'),
                onPressed: () => _triggerImmediateEscalation('MANUAL_SOS'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. ESCALATED VIEW
  Widget _buildEscalatedView() {
    return Center(
      key: const ValueKey('escalated'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isEscalating) ...[
            const CircularProgressIndicator(color: AppConstants.emergencyRed),
            const SizedBox(height: 20),
            const Text(
              'Gathering GPS location and preparing emergency SMS...',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.textLight, fontSize: 14),
            ),
          ] else ...[
            const Icon(Icons.check_circle_outline, color: AppConstants.safeGreen, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Escalation Completed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textLight),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _walkState = WalkState.setup),
              child: const Text('New Safe Walk'),
            ),
          ],
        ],
      ),
    );
  }

  /// 5. ARRIVED SAFELY VIEW
  Widget _buildArrivedView() {
    return Center(
      key: const ValueKey('arrived'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppConstants.safeGreen.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppConstants.safeGreen, size: 70),
          ),
          const SizedBox(height: 24),
          const Text(
            'Arrived Safely! 🎉',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textLight),
          ),
          const SizedBox(height: 8),
          Text(
            'You completed your journey to ${_destinationController.text}.',
            style: const TextStyle(fontSize: 14, color: AppConstants.textMuted),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => setState(() => _walkState = WalkState.setup),
            child: const Text('Start Another Walk'),
          ),
        ],
      ),
    );
  }
}
