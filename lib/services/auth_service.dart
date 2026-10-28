import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Sign In with Email & Password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _parseAuthError(e);
    } catch (e) {
      throw 'Authentication error: ${e.toString()}';
    }
  }

  /// Register new user with Email, Password & Full Name
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName.trim());
        await credential.user!.reload();
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _parseAuthError(e);
    } catch (e) {
      throw 'Registration error: ${e.toString()}';
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  /// Friendly error messages for student/examiner UX
  String _parseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user registered with this email. Please sign up first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password or email. Please check your credentials.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'The email format entered is invalid.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }
}
