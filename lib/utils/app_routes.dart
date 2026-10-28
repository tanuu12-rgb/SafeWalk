import 'package:flutter/material.dart';
import '../screens/auth/login_register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/contacts/emergency_contacts_screen.dart';
import '../screens/safe_walk/safe_walk_screen.dart';
import '../screens/reports/report_unsafe_screen.dart';
import '../screens/activity/activity_stats_screen.dart';
import '../screens/permission/permission_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String contacts = '/contacts';
  static const String safeWalk = '/safewalk';
  static const String reportUnsafe = '/report';
  static const String activityStats = '/activity';
  static const String permission = '/permission';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginRegisterScreen(),
        home: (context) => const HomeScreen(),
        contacts: (context) => const EmergencyContactsScreen(),
        safeWalk: (context) => const SafeWalkScreen(),
        reportUnsafe: (context) => const ReportUnsafeScreen(),
        activityStats: (context) => const ActivityStatsScreen(),
        permission: (context) => const PermissionScreen(),
      };
}
