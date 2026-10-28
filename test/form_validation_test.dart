import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafeWalk Form Validation Unit Tests', () {
    test('Email validator rejects empty string and malformed emails', () {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

      String? validateEmail(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Email address is required';
        }
        if (!emailRegex.hasMatch(value.trim())) {
          return 'Enter a valid email address';
        }
        return null;
      }

      expect(validateEmail(''), 'Email address is required');
      expect(validateEmail('   '), 'Email address is required');
      expect(validateEmail('plainaddress'), 'Enter a valid email address');
      expect(validateEmail('user@'), 'Enter a valid email address');
      expect(validateEmail('user@domain'), 'Enter a valid email address');
      expect(validateEmail('student@college.edu'), isNull);
    });

    test('Password validator enforces minimum length of 6 characters', () {
      String? validatePassword(String? value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      }

      expect(validatePassword(null), 'Password is required');
      expect(validatePassword(''), 'Password is required');
      expect(validatePassword('12345'), 'Password must be at least 6 characters');
      expect(validatePassword('safepassword'), isNull);
    });

    test('Emergency Contact phone validator enforces digit pattern', () {
      final phoneRegex = RegExp(r'^\+?[0-9\s\-]{7,15}$');

      String? validatePhone(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Phone number is required for SMS escalations';
        }
        if (!phoneRegex.hasMatch(value.trim())) {
          return 'Enter a valid phone number (digits only)';
        }
        return null;
      }

      expect(validatePhone(''), 'Phone number is required for SMS escalations');
      expect(validatePhone('abc-def'), 'Enter a valid phone number (digits only)');
      expect(validatePhone('12345'), 'Enter a valid phone number (digits only)');
      expect(validatePhone('+1234567890'), isNull);
      expect(validatePhone('9876543210'), isNull);
    });

    test('Emergency Contact name requires at least 2 characters', () {
      String? validateName(String? value) {
        if (value == null || value.trim().length < 2) {
          return 'Please enter a name (at least 2 characters)';
        }
        return null;
      }

      expect(validateName(''), 'Please enter a name (at least 2 characters)');
      expect(validateName('A'), 'Please enter a name (at least 2 characters)');
      expect(validateName('Mom'), isNull);
      expect(validateName('Campus Security'), isNull);
    });
  });
}
