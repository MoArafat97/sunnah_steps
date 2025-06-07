import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;

/// Helper function to get the appropriate font family
/// Returns 'Cairo' if available, otherwise uses system default
String _getFontFamily() {
  // For now, using system default. When Cairo font is added to assets,
  // this will automatically use Cairo font
  return 'Cairo'; // Flutter will fallback to system default if Cairo is not found
}

/// Three-step swipe-up welcome flow that replaces the old welcome screen
/// 1. Cream intro page (soft, artistic)
/// 2. Sunnah Reclaim page (dramatic typewriter "IT'S TIME TO RECLAIM THE SUNNAH")
/// 3. Star-field transition → auto-navigate to AuthScreen
class OnboardingFlow extends StatefulWidget {
  final int initialPage;

  const OnboardingFlow({super.key, this.initialPage = 0});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late PageController _controller;
  bool _hasNavigatedToAuth = false; // Flag to prevent double navigation

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePageChanged(int index) {
    if (index == 2 && !_hasNavigatedToAuth) {
      // Navigate to ReadyCheckPage instead of auth
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_hasNavigatedToAuth) {
          _hasNavigatedToAuth = true;
          context.go('/ready-check');
        }
      });
    }
  }

  void _navigateToAuth() {
    if (!_hasNavigatedToAuth) {
      _hasNavigatedToAuth = true;
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EE), // Ensure cream background for entire scaffold
      body: PageView(
        controller: _controller,
        scrollDirection: Axis.vertical,
        onPageChanged: _handlePageChanged,
        children: [
          const _CreamIntroPage(),
          _SunnahReclaimPage(onNavigateToAuth: _navigateToAuth),
          const _StarFieldPage(),
        ],
      ),
    );
  }
}

/// Page 1: Elegant minimalist intro page with enhanced typewriter animation
class _CreamIntroPage extends StatefulWidget {
  const _CreamIntroPage();

  @override
  State<_CreamIntroPage> createState() => _CreamIntroPageState();
}

class _CreamIntroPageState extends State<_CreamIntroPage>
    with TickerProviderStateMixin {
  late AnimationController _swipeController;
  late Animation<double> _swipeAnimation;
  late Animation<double> _swipeTranslateAnimation;

  @override
  void initState() {
    super.initState();

    // Enhanced swipe indicator animation with up-down pulse
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _swipeAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeInOut,
    ));

    _swipeTranslateAnimation = Tween<double>(
      begin: 0.0,
      end: -8.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeInOut,
    ));

    // Start gentle pulse animation
    _swipeController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F3EE), // Exact background color
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Main content area - centered vertically and horizontally
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: const _EnhancedTypewriterText(),
                ),
              ),
            ),

            // Enhanced swipe indicator at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: AnimatedBuilder(
                animation: _swipeController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _swipeTranslateAnimation.value),
                    child: Opacity(
                      opacity: _swipeAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: const Color(0xFF8B4513),
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SWIPE UP TO CONTINUE',
                            style: TextStyle(
                              fontFamily: _getFontFamily(),
                              fontSize: 12,
                              color: const Color(0xFF8B4513).withValues(alpha: 0.6),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page 2: Dramatic spiritual message with typewriter effects
class _SunnahReclaimPage extends StatefulWidget {
  final VoidCallback onNavigateToAuth;

  const _SunnahReclaimPage({required this.onNavigateToAuth});

  @override
  State<_SunnahReclaimPage> createState() => _SunnahReclaimPageState();
}

class _SunnahReclaimPageState extends State<_SunnahReclaimPage>
    with TickerProviderStateMixin {
  // Animation controllers for each line
  late AnimationController _line1Controller;
  late AnimationController _line2Controller;
  late AnimationController _line3Controller;
  late AnimationController _pulseController;
  late AnimationController _entranceController;
  late AnimationController _glowPulseController;
  late AnimationController _floatController;

  // Text display states
  String _displayedText1 = '';
  String _displayedText2 = '';
  String _displayedText3 = '';

  // Animation states
  late Animation<double> _line1Scale;
  late Animation<double> _line2Blur;
  late Animation<double> _line3Glow;
  late Animation<double> _pulseOpacity;
  late Animation<double> _entranceFade;
  late Animation<double> _entranceScale;
  late Animation<double> _glowPulse;
  late Animation<double> _floatOffset;

  // Text content
  final String _text1 = 'IT\'S TIME';
  final String _text2 = 'TO RECLAIM';
  final String _text3 = 'THE SUNNAH';

  AudioPlayer? _audioPlayer;
  bool _hasPlayedChime = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _line1Controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _line2Controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _line3Controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // New enhancement controllers
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Initialize animations
    _line1Scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _line1Controller, curve: Curves.easeInOut),
    );

    _line2Blur = Tween<double>(begin: 4.0, end: 0.0).animate(
      CurvedAnimation(parent: _line2Controller, curve: Curves.easeOutCubic),
    );

    _line3Glow = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _line3Controller, curve: Curves.easeOutCubic),
    );

    _pulseOpacity = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // New enhancement animations
    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _entranceScale = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _glowPulse = Tween<double>(begin: 0.5, end: 0.8).animate(
      CurvedAnimation(parent: _glowPulseController, curve: Curves.easeInOut),
    );

    _floatOffset = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Start entrance animation immediately
    _entranceController.forward();

    // Start typewriter sequence after entrance
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _startTypewriterSequence();
    });
  }

  Future<void> _startTypewriterSequence() async {
    // Line 1: "IT'S TIME"
    await _typewriteLine(_text1, 1);
    if (mounted) {
      // Scale pulse effect
      _line1Controller.forward().then((_) {
        if (mounted) _line1Controller.reverse();
      });
    }

    // Delay before next line
    await Future.delayed(const Duration(milliseconds: 400));

    // Line 2: "TO RECLAIM"
    await _typewriteLine(_text2, 2);
    if (mounted) {
      // Blur-to-sharp effect
      _line2Controller.forward();
    }

    // Delay before final line
    await Future.delayed(const Duration(milliseconds: 400));

    // Line 3: "THE SUNNAH" (slower for emphasis)
    await _typewriteLine(_text3, 3, slower: true);
    if (mounted) {
      // Golden glow effect
      _line3Controller.forward();
      // Start glow pulse animation
      _glowPulseController.repeat(reverse: true);
      // Haptic feedback
      HapticFeedback.lightImpact();
      // Play chime sound
      _playChime();
      // Start pulse and float animation for "Are you ready?"
      _pulseController.repeat(reverse: true);
      _floatController.repeat(reverse: true);
    }
  }

  Future<void> _typewriteLine(String text, int lineNumber, {bool slower = false}) async {
    final delay = slower ? 120 : 80; // Slower for emphasis on line 3

    for (int i = 0; i <= text.length; i++) {
      if (mounted) {
        setState(() {
          switch (lineNumber) {
            case 1:
              _displayedText1 = text.substring(0, i);
              break;
            case 2:
              _displayedText2 = text.substring(0, i);
              break;
            case 3:
              _displayedText3 = text.substring(0, i);
              break;
          }
        });
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }

  Future<void> _playChime() async {
    if (_hasPlayedChime) return; // Only play once

    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer?.setVolume(0.15); // Very low volume
      await _audioPlayer?.play(AssetSource('sfx/light_chime.mp3'));
      _hasPlayedChime = true;
    } catch (e) {
      print('Failed to play chime: $e');
      // Graceful fallback - continue without sound
    }
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _line3Controller.dispose();
    _pulseController.dispose();
    _entranceController.dispose();
    _glowPulseController.dispose();
    _floatController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Transform.scale(
          scale: _entranceScale.value,
          child: Opacity(
            opacity: _entranceFade.value,
            child: Container(
              color: const Color(0xFFF5F3EE), // Solid cream background
              child: SafeArea(
                child: RepaintBoundary(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Main text content with soft radial glow
                      Expanded(
                        child: Center(
                          child: Container(
                            // Soft radial light behind entire text block
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD580).withValues(alpha: 0.12),
                                  blurRadius: 120,
                                  spreadRadius: 60,
                                  offset: Offset.zero,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Line 1: "IT'S TIME"
                                  AnimatedBuilder(
                                    animation: _line1Controller,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _line1Scale.value,
                                        child: Text(
                                          _displayedText1,
                                          textAlign: TextAlign.center,
                                          semanticsLabel: 'It\'s time',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF8B4513),
                                            letterSpacing: 1.2,
                                            height: 1.2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Line 2: "TO RECLAIM"
                                  AnimatedBuilder(
                                    animation: _line2Controller,
                                    builder: (context, child) {
                                      return ImageFiltered(
                                        imageFilter: ui.ImageFilter.blur(
                                          sigmaX: _line2Blur.value,
                                          sigmaY: _line2Blur.value,
                                        ),
                                        child: Text(
                                          _displayedText2,
                                          textAlign: TextAlign.center,
                                          semanticsLabel: 'To reclaim',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF8B4513),
                                            letterSpacing: 1.2,
                                            height: 1.2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Line 3: "THE SUNNAH" with enhanced pulsing golden glow
                                  AnimatedBuilder(
                                    animation: Listenable.merge([_line3Controller, _glowPulseController]),
                                    builder: (context, child) {
                                      final glowIntensity = _line3Glow.value * _glowPulse.value;
                                      return Container(
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFF5C518).withValues(alpha: 0.3 * _glowPulse.value),
                                              blurRadius: glowIntensity,
                                              spreadRadius: glowIntensity * 0.5,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _displayedText3,
                                          textAlign: TextAlign.center,
                                          semanticsLabel: 'The Sunnah',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF8B4513),
                                            letterSpacing: 1.2,
                                            height: 1.2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Enhanced "Are you ready?" with float and pulse
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40.0),
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_pulseController, _floatController]),
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatOffset.value),
                              child: Opacity(
                                opacity: _pulseOpacity.value,
                                child: Text(
                                  'Are you ready?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF8B4513),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Simple static text widget to avoid animation controller issues
class _EnhancedTypewriterText extends StatelessWidget {
  const _EnhancedTypewriterText();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Line 1: "IN A WORLD FULL OF..." (20-22sp, Regular, Black)
        Text(
          'IN A WORLD FULL OF...',
          textAlign: TextAlign.center,
          semanticsLabel: 'In a world full of distractions',
          style: TextStyle(
            fontFamily: _getFontFamily(),
            fontSize: 21, // 20-22sp
            fontWeight: FontWeight.w400, // Regular
            color: const Color(0xFF000000), // Black
            letterSpacing: 1.2,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 16),

        // Line 2: "DISTRACTIONS..." (22-24sp, Medium, Brown)
        Text(
          'DISTRACTIONS...',
          textAlign: TextAlign.center,
          semanticsLabel: 'Distractions everywhere',
          style: TextStyle(
            fontFamily: _getFontFamily(),
            fontSize: 23, // 22-24sp
            fontWeight: FontWeight.w500, // Medium
            color: const Color(0xFF8B4513), // Brown
            letterSpacing: 1.2,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 16),

        // Line 3: "WE FORGET OUR FITRAH" (26-28sp, Bold, Brown)
        Text(
          'WE FORGET OUR FITRAH',
          textAlign: TextAlign.center,
          semanticsLabel: 'We forget our natural state, our fitrah',
          style: TextStyle(
            fontFamily: _getFontFamily(),
            fontSize: 27, // 26-28sp
            fontWeight: FontWeight.w700, // Bold
            color: const Color(0xFF8B4513), // Brown
            letterSpacing: 1.2,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}



/// Page 3: Simple fade transition page
class _StarFieldPage extends StatefulWidget {
  const _StarFieldPage();

  @override
  State<_StarFieldPage> createState() => _StarFieldPageState();
}

class _StarFieldPageState extends State<_StarFieldPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: const Color(0xFFF5F3EE), // Cream background
            child: const Center(
              child: Text(
                'Welcome to your journey...',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  color: Color(0xFF8B4513),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
