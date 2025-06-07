import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../services/user_flags_service.dart';
import '../../services/checklist_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Navigate to dashboard after successful signup
  Future<void> _navigateAfterSignup() async {
    // Mark onboarding as completed in Firestore (primary source of truth)
    await FirebaseService.markOnboardingCompleted();

    // Also mark in local services for consistency with existing features
    await UserFlagsService.markOnboardingCompleted();
    await ChecklistService.instance.markOnboardingCompleted();

    // Only show the welcome prompt if brand-new.
    final seen = await UserFlagsService.hasSeenChecklistPrompt();

    if (mounted) {
      // Use GoRouter for consistent navigation
      if (seen) {
        context.go('/dashboard');
      } else {
        context.go('/checklist-welcome');
      }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'Please agree to the terms and services to continue';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user with email and password
      final userCredential = await FirebaseService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Create user document in Firestore
      await FirebaseService.createUserDocument(userCredential.user!);

      if (mounted) {
        await _navigateAfterSignup();
      }
    } catch (e) {
      setState(() {
        // Handle Firebase Auth exceptions with improved messages
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              _errorMessage = 'An account already exists with this email. Try signing in instead.';
              break;
            case 'weak-password':
              _errorMessage = 'Password is too weak. Please choose a stronger password.';
              break;
            case 'invalid-email':
              _errorMessage = 'Invalid email address.';
              break;
            default:
              _errorMessage = e.message ?? 'Sign-up failed. Please try again.';
          }
        } else {
          _errorMessage = 'Sign-up failed: ${e.toString()}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  Widget _buildTitle() {
    return Stack(
      children: [
        // Golden highlight behind text
        Positioned(
          left: 0,
          right: 0,
          top: 8,
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFFEFBC4), // Light golden yellow
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        // Title text
        Text(
          'SIGN UP',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513), // Brown color
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        fontFamily: 'Cairo',
        color: Color(0xFF8B4513),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          color: const Color(0xFF8B4513).withOpacity(0.7),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF8B4513),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF8B4513),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF8B4513),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        filled: false,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF5F3EE), // Same background as onboarding pages
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Back button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF8B4513)),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.go('/');
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Spacer(),
                  ],
                ),

                const SizedBox(height: 24),

                // Title with golden highlight
                _buildTitle(),

                const SizedBox(height: 24),

                // Signup form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Address
                      _buildTextField(
                        controller: _emailController,
                        labelText: 'EMAIL ADDRESS',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password
                      _buildTextField(
                        controller: _passwordController,
                        labelText: 'PASSWORD',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF8B4513),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password
                      _buildTextField(
                        controller: _confirmPasswordController,
                        labelText: 'CONFIRM PASSWORD',
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF8B4513),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _signUp(),
                      ),

                      const SizedBox(height: 20),

                      // Terms and Conditions Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            onChanged: (bool? value) {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF8B4513),
                            checkColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFF8B4513),
                              width: 1.5,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'AGREE TO TERMS AND SERVICES',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: Color(0xFF8B4513),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Continue Button with golden highlight
                      _buildContinueButton(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: _isLoading ? null : () {
        HapticFeedback.mediumImpact();
        _signUp();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Golden highlight behind text
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFFEFBC4), // Light golden yellow
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Button container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF8B4513),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                    ),
                  )
                : const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ],
      ),
    );
  }
}
