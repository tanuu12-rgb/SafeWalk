import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/app_constants.dart';
import 'utils/app_theme.dart';
import 'utils/app_routes.dart';
import 'screens/auth/login_register_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Graceful Firebase initialization
  // Catches and logs errors if google-services.json is still using the placeholder
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase.initializeApp() warning (normal before adding google-services.json): $e');
  }

  runApp(const SafeWalkApp());
}

class SafeWalkApp extends StatelessWidget {
  const SafeWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.initial,
      routes: {
        AppRoutes.initial: (context) => const AuthGate(),
        ...AppRoutes.routes,
      },
    );
  }
}

/// Determines whether to show HomeScreen or LoginRegisterScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // If Firebase is initialized, listen to auth changes; otherwise fallback gracefully to Login
    try {
      final auth = FirebaseAuth.instance;
      return StreamBuilder<User?>(
        stream: auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppConstants.primaryViolet),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          return const LoginRegisterScreen();
        },
      );
    } catch (_) {
      // Fallback if Firebase not yet initialized
      return const LoginRegisterScreen();
    }
  }
}
