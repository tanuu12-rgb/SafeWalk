import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_routes.dart';

class SafeWalkDrawer extends StatelessWidget {
  const SafeWalkDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final userName = user?.displayName ?? 'SafeWalk User';
    final userEmail = user?.email ?? 'user@safewalk.local';

    return Drawer(
      backgroundColor: AppConstants.bgDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppConstants.primaryDark, AppConstants.primaryViolet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.security,
                        color: AppConstants.primaryViolet,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userEmail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: AppConstants.textLight),
            title: const Text('Dashboard', style: TextStyle(color: AppConstants.textLight)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined, color: AppConstants.primaryLight),
            title: const Text('Safe Walk Timer', style: TextStyle(color: AppConstants.textLight)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.safeWalk);
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_phone_outlined, color: AppConstants.safeGreen),
            title: const Text('Emergency Contacts', style: TextStyle(color: AppConstants.textLight)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.contacts);
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_problem_outlined, color: AppConstants.warningOrange),
            title: const Text('Report Unsafe Area', style: TextStyle(color: AppConstants.textLight)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.reportUnsafe);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined, color: AppConstants.primaryLight),
            title: const Text('Activity & Stats', style: TextStyle(color: AppConstants.textLight)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.activityStats);
            },
          ),
          const Divider(color: Color(0xFF334155)),
          ListTile(
            leading: const Icon(Icons.logout, color: AppConstants.emergencyRed),
            title: const Text('Sign Out', style: TextStyle(color: AppConstants.emergencyRed)),
            onTap: () async {
              Navigator.pop(context);
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}
