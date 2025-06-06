import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../services/user_flags_service.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String? _selectedGender;
  bool _isSignUpMode = false; // Toggle between sign-in and sign-up

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Navigate to appropriate screen after successful authentication
  Future<void> _navigateAfterAuth() async {
    // Check if user has completed onboarding (from Firestore)
    final hasCompletedOnboarding = await FirebaseService.hasCompletedOnboarding();

    if (hasCompletedOnboarding) {
      // User has already completed onboarding, go to dashboard
      context.go('/dashboard');
    } else {
      // User hasn't completed onboarding, start onboarding flow
      context.go('/intro');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await FirebaseService.signInWithGoogle();

      // Create user document in Firestore if it's a new user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await FirebaseService.createUserDocument(userCredential.user!);
      }

      if (mounted) {
        await _navigateAfterAuth();
      }
    } catch (e) {
      setState(() {
        // Handle Firebase Auth exceptions and other errors
        if (e is FirebaseAuthException) {
          _errorMessage = e.message ?? 'Google sign-in failed. Please try again.';
        } else if (e.toString().contains('Google sign-in configuration error')) {
          _errorMessage = 'Google sign-in configuration error. Please ensure SHA1 fingerprint is added to Firebase Console. Try using email/password below.';
        } else if (e.toString().contains('cancelled')) {
          _errorMessage = 'Google sign-in was cancelled.';
        } else if (e.toString().contains('network')) {
          _errorMessage = 'Network error. Please check your connection and try again.';
        } else {
          _errorMessage = 'Google sign-in failed: ${e.toString()}. Try using email/password below.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Ensure user document exists (for existing users who might not have one)
      final currentUser = FirebaseService.currentUser;
      if (currentUser != null) {
        await FirebaseService.createUserDocument(currentUser);
      }

      if (mounted) {
        await _navigateAfterAuth();
      }
    } catch (e) {
      setState(() {
        // Provide more specific error messages
        if (e.toString().contains('user-not-found')) {
          _errorMessage = 'No account found with this email. Try creating an account.';
        } else if (e.toString().contains('wrong-password')) {
          _errorMessage = 'Incorrect password. Please try again.';
        } else if (e.toString().contains('invalid-email')) {
          _errorMessage = 'Invalid email address.';
        } else {
          _errorMessage = 'Sign-in failed: ${e.toString()}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithEmailPassword() async {
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
      final userCredential = await FirebaseService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Combine first and last name for display name
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      // Update the user's display name
      await userCredential.user!.updateDisplayName(fullName);

      // Create user document in Firestore with name
      await FirebaseService.createUserDocumentWithName(
        userCredential.user!,
        fullName,
      );

      if (mounted) {
        await _navigateAfterAuth();
      }
    } catch (e) {
      setState(() {
        // Handle Firebase Auth exceptions with improved messages
        if (e is FirebaseAuthException) {
          _errorMessage = e.message ?? 'Sign-up failed. Please try again.';
        } else if (e.toString().contains('email-already-in-use')) {
          _errorMessage = 'An account already exists with this email. Try signing in instead.';
        } else if (e.toString().contains('weak-password')) {
          _errorMessage = 'Password is too weak. Please choose a stronger password.';
        } else if (e.toString().contains('invalid-email')) {
          _errorMessage = 'Invalid email address.';
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

  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B4513),
              onPrimary: Colors.white,
              surface: Color(0xFFF5F3EE),
              onSurface: Color(0xFF8B4513),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthdayController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
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
            top: false, // Remove top padding to get closer to status bar
            child: SingleChildScrollView( // Prevent overflow
              padding: EdgeInsets.fromLTRB(
                24.0,
                16.0,
                24.0,
                24.0 + MediaQuery.of(context).viewInsets.bottom
              ), // Add keyboard padding
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button positioned at the top
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryTeal),
                          onPressed: () => context.go('/'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Spacer(),
                      ],
                    ),

                    const SizedBox(height: 8), // Small gap after back button

                    // Form content
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                // Title with enhanced styling
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.enhancedCardDecoration,
                  child: Column(
                    children: [
                      // Logo section
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.primaryTeal.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.mosque,
                          color: AppTheme.primaryTeal,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSignUpMode ? 'Create Account' : 'Welcome Back',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTeal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUpMode
                          ? 'Start your Sunnah journey'
                          : 'Continue your Sunnah journey',
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Google Sign-In Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: Text(_isSignUpMode ? 'Sign up with Google' : 'Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Dynamic form fields based on mode
                if (_isSignUpMode) ...[
                  // NEW SIGNUP DESIGN - First Name and Last Name (side by side)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name',
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
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xFF8B4513),
                            fontSize: 16,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            if (value.trim().length < 2) {
                              return 'Too short';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
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
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Color(0xFF8B4513),
                            fontSize: 16,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            if (value.trim().length < 2) {
                              return 'Too short';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ] else ...[
                  // ORIGINAL SIGN IN DESIGN - Just email and password
                ],

                // Email field (for both modes)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: _isSignUpMode ? 'Email Address' : 'Email',
                    labelStyle: _isSignUpMode ? TextStyle(
                      fontFamily: 'Cairo',
                      color: const Color(0xFF8B4513).withOpacity(0.7),
                      fontSize: 14,
                    ) : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_isSignUpMode ? 8 : 12),
                      borderSide: BorderSide(
                        color: _isSignUpMode ? const Color(0xFF8B4513) : Colors.grey,
                        width: 1,
                      ),
                    ),
                    enabledBorder: _isSignUpMode ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF8B4513),
                        width: 1,
                      ),
                    ) : null,
                    focusedBorder: _isSignUpMode ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF8B4513),
                        width: 1.5,
                      ),
                    ) : null,
                    prefixIcon: _isSignUpMode ? null : const Icon(Icons.email),
                    filled: false,
                    contentPadding: _isSignUpMode ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16) : null,
                  ),
                  style: _isSignUpMode ? const TextStyle(
                    fontFamily: 'Cairo',
                    color: Color(0xFF8B4513),
                    fontSize: 16,
                  ) : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isSignUpMode ? _obscurePassword : true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: _isSignUpMode ? TextStyle(
                      fontFamily: 'Cairo',
                      color: const Color(0xFF8B4513).withOpacity(0.7),
                      fontSize: 14,
                    ) : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_isSignUpMode ? 8 : 12),
                      borderSide: BorderSide(
                        color: _isSignUpMode ? const Color(0xFF8B4513) : Colors.grey,
                        width: 1,
                      ),
                    ),
                    enabledBorder: _isSignUpMode ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF8B4513),
                        width: 1,
                      ),
                    ) : null,
                    focusedBorder: _isSignUpMode ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF8B4513),
                        width: 1.5,
                      ),
                    ) : null,
                    prefixIcon: _isSignUpMode ? null : const Icon(Icons.lock),
                    suffixIcon: _isSignUpMode ? IconButton(
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
                    ) : null,
                    filled: false,
                    contentPadding: _isSignUpMode ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16) : null,
                  ),
                  style: _isSignUpMode ? const TextStyle(
                    fontFamily: 'Cairo',
                    color: Color(0xFF8B4513),
                    fontSize: 16,
                  ) : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Sign In/Sign Up button
                ElevatedButton(
                  onPressed: _isLoading
                    ? null
                    : (_isSignUpMode ? _signUpWithEmailPassword : _signInWithEmailPassword),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      : Text(
                          _isSignUpMode ? 'Create Account' : 'Sign In',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

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
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 16),

                // Toggle between Sign In and Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUpMode
                        ? 'Already have an account? '
                        : 'Don\'t have an account? ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUpMode = !_isSignUpMode;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _isSignUpMode ? 'Sign In' : 'Create Account',
                        style: TextStyle(
                          color: Colors.teal.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Skip for now link
                TextButton(
                  onPressed: () => context.go('/intro'),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: Colors.teal.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),


                        ],
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
