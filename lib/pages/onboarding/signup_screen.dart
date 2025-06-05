import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../services/user_flags_service.dart';
import '../../services/checklist_service.dart';
import '../../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

      // Update the user's display name
      await userCredential.user!.updateDisplayName(_nameController.text.trim());

      // Create user document in Firestore with name
      await FirebaseService.createUserDocumentWithName(
        userCredential.user!,
        _nameController.text.trim(),
      );

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

  Future<void> _skipSignup() async {
    // Check if user can bypass signup requirements
    final canBypass = await UserFlagsService.canBypassSignup();
    
    if (canBypass) {
      // Allow bypass for admin/testing users
      await _navigateAfterSignup();
    } else {
      // Show message that signup is required
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account creation is required to continue'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AppTheme.backgroundContainer(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button positioned at the top
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppTheme.primaryTeal),
                        onPressed: () => context.go('/onboarding/micro-lessons'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                    ],
                  ),

                  // Main content with center alignment
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),

                          // Welcome card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: AppTheme.enhancedCardDecoration,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 48,
                                  color: AppTheme.primaryTeal,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Create Your Account',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryTeal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Join the Sunnah Steps community and start your spiritual journey.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.secondaryText,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Signup form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Name field
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    hintText: 'Enter your full name',
                                    prefixIcon: const Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    if (value.trim().length < 2) {
                                      return 'Name must be at least 2 characters';
                                    }
                                    return null;
                                  },
                                  textInputAction: TextInputAction.next,
                                ),

                                const SizedBox(height: 16),

                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'Enter your email',
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
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
                                  textInputAction: TextInputAction.next,
                                ),

                                const SizedBox(height: 16),

                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _signUp(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Error message
                          if (_errorMessage != null)
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
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          if (_errorMessage != null) const SizedBox(height: 16),

                          // Create Account button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 16),

                          // Skip button (only for admin/testing)
                          TextButton(
                            onPressed: _skipSignup,
                            child: Text(
                              'Skip for now',
                              style: TextStyle(
                                color: Colors.teal.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
