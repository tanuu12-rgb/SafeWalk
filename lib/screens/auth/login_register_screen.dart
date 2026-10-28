import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreeToDisclaimer = true; // Checkbox requirement

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isLoginMode && !_agreeToDisclaimer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge the safety prototype disclaimer.'),
          backgroundColor: AppConstants.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await _authService.signInWithEmailPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _authService.registerWithEmailPassword(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppConstants.emergencyRed,
            action: SnackBarAction(
              label: 'Bypass (Demo)',
              textColor: Colors.white,
              onPressed: () {
                // Allows lab examiners to enter even if Firebase project is offline
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo (Local Asset)
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryViolet.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppConstants.bgCard,
                              child: const Icon(
                                Icons.shield_rounded,
                                color: AppConstants.primaryLight,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // App Title & Tagline
                    const Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppConstants.textLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      AppConstants.appTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppConstants.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Card Container with glassmorphism
                    Container(
                      padding: const EdgeInsets.all(22.0),
                      decoration: AppTheme.glassCardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isLoginMode ? 'Welcome Back' : 'Create Safety Account',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isLoginMode
                                ? 'Sign in to access your contacts and safe walks'
                                : 'Fill in your details to secure your journeys',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppConstants.textMuted,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Full Name (Only in Registration Mode)
                          if (!_isLoginMode) ...[
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length < 2) {
                                  return 'Please enter your full name (at least 2 letters)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email Address
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email address is required';
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password (Only in Registration Mode)
                          if (!_isLoginMode) ...[
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscurePassword,
                              decoration: const InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: Icon(Icons.lock_reset_outlined),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Checkbox (Syllabus Requirement)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _agreeToDisclaimer,
                                  activeColor: AppConstants.primaryViolet,
                                  onChanged: (val) {
                                    setState(() => _agreeToDisclaimer = val ?? false);
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    'I acknowledge this is a college lab safety prototype and requires network/location permissions.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppConstants.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Submit Button with Loading Indicator
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      _isLoginMode ? 'Sign In' : 'Create Account',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Toggle between Login & Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLoginMode
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: const TextStyle(color: AppConstants.textMuted, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _switchMode,
                          child: Text(
                            _isLoginMode ? 'Register' : 'Sign In',
                            style: const TextStyle(
                              color: AppConstants.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Direct Demo Access for College Evaluation
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.flash_on, color: AppConstants.safeGreen, size: 18),
                        label: const Text(
                          'Quick Lab Demo Access (Bypass Login)',
                          style: TextStyle(color: AppConstants.safeGreen, fontSize: 13),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRoutes.home);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
