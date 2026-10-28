import 'package:flutter/material.dart';
import '../../models/emergency_contact.dart';
import '../../models/offline_alert.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_db_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _storageService = LocalStorageService();
  final _dbService = FirebaseDbService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<EmergencyContact> _contacts = [];
  List<OfflineAlert> _recentAlerts = [];
  bool _isLoading = true;
  int _pendingSyncCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadDashboardData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await _storageService.loadContacts();
      final alerts = await _storageService.loadOfflineAlerts();
      final pending = alerts.where((a) => !a.isSynced).length;

      // Sync contacts to Firebase in background if logged in
      _dbService.syncContactsToFirebase(contacts);

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _recentAlerts = alerts.take(4).toList();
          _pendingSyncCount = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _retrySync() async {
    final count = await _dbService.retrySyncOfflineAlerts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Successfully synced $count offline alert(s) to Firebase!'
                : 'All alerts are already synchronized or cloud is offline.',
          ),
          backgroundColor: count > 0 ? AppConstants.safeGreen : AppConstants.bgCardLight,
        ),
      );
      _loadDashboardData();
    }
  }

  /// Triggers immediate Manual SOS escalation
  void _triggerManualSos(String triggerSource) {
    // Navigate directly to SafeWalk screen in escalation mode or trigger immediate modal
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppConstants.emergencyRed, size: 28),
            SizedBox(width: 10),
            Text('Manual SOS Triggered', style: TextStyle(color: AppConstants.textLight)),
          ],
        ),
        content: Text(
          'Triggered via $triggerSource.\n\nSafeWalk will fetch your current GPS coordinates, write an alert to Firebase/local storage, and compose an emergency SMS to your contacts.',
          style: const TextStyle(color: AppConstants.textMuted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppConstants.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.emergencyRed),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.safeWalk, arguments: {'autoSos': true});
            },
            child: const Text('Execute SOS Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final displayName = user?.displayName ?? 'SafeWalker';
    final primaryContact = _contacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => _contacts.isNotEmpty
          ? _contacts.first
          : EmergencyContact(
              id: 'none',
              name: 'None Set',
              phoneNumber: 'No number',
              relationship: 'None',
              createdAt: DateTime.now(),
            ),
    );

    return Scaffold(
      drawer: const SafeWalkDrawer(),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: AppConstants.primaryLight),
            ),
            const SizedBox(width: 8),
            const Text('SafeWalk'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Dashboard',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryViolet))
            : RefreshIndicator(
                color: AppConstants.primaryViolet,
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header greeting
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $displayName 👋',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppConstants.textLight,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Stay protected wherever you walk',
                                style: TextStyle(fontSize: 13, color: AppConstants.textMuted),
                              ),
                            ],
                          ),
                          // Quick report icon button
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add_location_alt_outlined),
                            tooltip: 'Report Unsafe Spot',
                            color: AppConstants.warningOrange,
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.reportUnsafe),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Offline sync banner if pending items exist
                      if (_pendingSyncCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppConstants.warningOrange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppConstants.warningOrange.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_off, color: AppConstants.warningOrange, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '$_pendingSyncCount offline alert(s) waiting to sync',
                                  style: const TextStyle(fontSize: 12, color: AppConstants.textLight),
                                ),
                              ),
                              TextButton(
                                onPressed: _retrySync,
                                child: const Text('Sync Now', style: TextStyle(color: AppConstants.warningOrange)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // LARGE SOS BUTTON (GestureDetector: onLongPress, onDoubleTap)
                      Center(
                        child: Column(
                          children: [
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: GestureDetector(
                                onLongPress: () => _triggerManualSos('Long Press on SOS'),
                                onDoubleTap: () => _triggerManualSos('Double Tap on SOS'),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Hold down or double-tap the red button to trigger Emergency SOS'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: AppTheme.sosButtonDecoration(),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.emergency_rounded, size: 58, color: Colors.white),
                                      SizedBox(height: 4),
                                      Text(
                                        'SOS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'HOLD or DOUBLE-TAP for Emergency SOS\n(Or shake your phone)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // START SAFE WALK CARD
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.safeWalk),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: AppTheme.gradientButtonDecoration(
                            colors: [AppConstants.primaryDark, AppConstants.primaryViolet],
                            radius: 20,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  'assets/images/walk_illustration.png',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.directions_walk_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Safe Walk',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Dead-man's switch timer with automated SMS escalation upon expiry.",
                                      style: TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // CONTACTS SUMMARY CARD (Row & Column layout)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.people_alt_outlined, color: AppConstants.safeGreen, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Emergency Contacts',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, AppRoutes.contacts),
                                  child: const Text('Manage', style: TextStyle(color: AppConstants.primaryLight)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppConstants.safeGreen.withOpacity(0.2),
                                  child: const Icon(Icons.shield_outlined, color: AppConstants.safeGreen, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        primaryContact.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.textLight,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Primary: ${primaryContact.phoneNumber} (${primaryContact.relationship})',
                                        style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppConstants.bgCardLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_contacts.length} Total',
                                    style: const TextStyle(fontSize: 12, color: AppConstants.textLight),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // SAFETY AWARENESS BANNER (Image.network requirement with fallback)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1508847154043-be5407fcaa5a?w=120&auto=format&fit=crop&q=60',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 50,
                                  height: 50,
                                  color: AppConstants.primaryViolet.withOpacity(0.2),
                                  child: const Icon(Icons.tips_and_updates, color: AppConstants.primaryLight),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Campus Lab Safety Prototype',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.textLight,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Always share your expected return time with roommates or family when traveling late.',
                                    style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // RECENT ACTIVITY / ALERTS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textLight,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.activityStats),
                            child: const Text('View All', style: TextStyle(color: AppConstants.primaryLight)),
                          ),
                        ],
                      ),
                      if (_recentAlerts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: AppTheme.glassCardDecoration(),
                          child: const Center(
                            child: Text(
                              'No recent alerts triggered. Stay safe!',
                              style: TextStyle(fontSize: 13, color: AppConstants.textMuted),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentAlerts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final alert = _recentAlerts[index];
                            final isSos = alert.alertType.contains('SOS');
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: AppTheme.glassCardDecoration(
                                borderColor: isSos
                                    ? AppConstants.emergencyRed.withOpacity(0.3)
                                    : AppConstants.primaryViolet.withOpacity(0.3),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSos ? Icons.warning_rounded : Icons.timer,
                                    color: isSos ? AppConstants.emergencyRed : AppConstants.primaryLight,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert.alertType.replaceAll('_', ' '),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppConstants.textLight,
                                          ),
                                        ),
                                        Text(
                                          alert.destination,
                                          style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: alert.isSynced
                                          ? AppConstants.safeGreen.withOpacity(0.15)
                                          : AppConstants.warningOrange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      alert.isSynced ? 'Cloud Synced' : 'Local Only',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: alert.isSynced ? AppConstants.safeGreen : AppConstants.warningOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
