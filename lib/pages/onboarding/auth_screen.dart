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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthdayController = TextEditingController();
  String? _selectedGender;

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();

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
    return Center(
      child: Text(
        'SIGN UP',
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B4513), // Brown color
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTableTextField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
    bool readOnly = false,
    void Function()? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        fontFamily: 'Cairo',
        color: Color(0xFF8B4513),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          color: const Color(0xFF8B4513).withValues(alpha: 0.7),
          fontSize: 14,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      style: const TextStyle(
        fontFamily: 'Cairo',
        color: Color(0xFF8B4513),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: 'GENDER',
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          color: const Color(0xFF8B4513).withValues(alpha: 0.7),
          fontSize: 14,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
      ],
      onChanged: (String? value) {
        setState(() {
          _selectedGender = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your gender';
        }
        return null;
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)), // Default to 20 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: GestureDetector(
        onPanUpdate: (details) {
          // Detect downward swipe to go back to onboarding
          if (details.delta.dy > 5) {
            _handleSwipeDown();
          }
        },
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

                // Back button (top left) and Skip button (top right)
                Row(
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        // Navigate back to the ReadyCheckPage
                        context.go('/ready-check');
                      },
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF8B4513),
                        size: 32,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.go('/dashboard');
                      },
                      child: const Text(
                        'SKIP',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: Color(0xFF8B4513),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Title with golden highlight
                _buildTitle(),

                const SizedBox(height: 24),

                // Signup form with table layout
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Table-style form using Column with bordered containers
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.75),
                            width: 2.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            // First Name | Last Name (two cells side by side)
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.black54,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.black54,
                                            width: 2.0,
                                          ),
                                        ),
                                      ),
                                      child: _buildTableTextField(
                                        controller: _firstNameController,
                                        labelText: 'FIRST NAME',
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Please enter your first name';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildTableTextField(
                                      controller: _lastNameController,
                                      labelText: 'LAST NAME',
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter your last name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Birthday | Gender (two cells side by side)
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.black54,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.black54,
                                            width: 2.0,
                                          ),
                                        ),
                                      ),
                                      child: _buildTableTextField(
                                        controller: _birthdayController,
                                        labelText: 'BIRTHDAY',
                                        readOnly: true,
                                        onTap: _selectDate,
                                        suffixIcon: const Icon(
                                          Icons.calendar_today,
                                          color: Color(0xFF8B4513),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Please select your birthday';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildGenderDropdown(),
                                  ),
                                ],
                              ),
                            ),
                            // Email Address (ONE SINGLE CELL - full width)
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.black54,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              child: _buildTableTextField(
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
                            ),
                            // Password (ONE SINGLE CELL - full width)
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.black54,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              child: _buildTableTextField(
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
                            ),
                            // Confirm Password (ONE SINGLE CELL - full width)
                            _buildTableTextField(
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
                          ],
                        ),
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

                      // Continue Button
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
      ),
    );
  }

  /// Handle swipe down gesture to go back to onboarding
  void _handleSwipeDown() {
    // Navigate back to the ReadyCheckPage
    context.go('/ready-check');
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: _isLoading ? null : () {
        HapticFeedback.mediumImpact();
        _signUp();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.75), // Thin gray border
            width: 2.0,
          ),
          borderRadius: BorderRadius.zero, // Square corners
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                  ),
                ),
              )
            : const Center(
                child: Text(
                  'CONTINUE',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
      ),
    );
  }


}
