import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Standalone Ready Check Page with split layout
/// Top half: "I AM READY" (navigates to auth)
/// Bottom half: "I AM NOT READY YET" (stays on page)
class ReadyCheckPage extends StatefulWidget {
  const ReadyCheckPage({super.key});

  @override
  State<ReadyCheckPage> createState() => _ReadyCheckPageState();
}

class _ReadyCheckPageState extends State<ReadyCheckPage>
    with TickerProviderStateMixin {
  
  // Local color constants to avoid theme bleed
  static const Color _creamBackground = Color(0xFFF5F3EE);
  static const Color _brownBackground = Color(0xFF7A4E2D);
  static const Color _brownText = Color(0xFF7A4E2D);
  static const Color _creamText = Color(0xFFF9F4EF);

  // Animation controllers for typewriter effects and pulse animations
  late AnimationController _topTypewriterController;
  late AnimationController _bottomTypewriterController;
  late AnimationController _topPulseController;
  late AnimationController _bottomPulseController;
  
  // Animation objects (nullable to handle hot reload)
  Animation<double>? _topPulseAnimation;
  Animation<double>? _bottomPulseAnimation;
  
  String _displayedTopText = '';
  String _displayedBottomText = '';
  final String _fullTopText = 'I AM READY';
  final String _fullBottomText = 'I AM NOT READY YET';

  @override
  void initState() {
    super.initState();
    _topTypewriterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _bottomTypewriterController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Initialize pulse controllers
    _topPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _bottomPulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    // Initialize pulse animations
    _topPulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _topPulseController,
      curve: Curves.easeInOut,
    ));
    
    _bottomPulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _bottomPulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start typewriter animations
    _startTypewriterAnimations();
  }

  @override
  void dispose() {
    _topTypewriterController.dispose();
    _bottomTypewriterController.dispose();
    _topPulseController.dispose();
    _bottomPulseController.dispose();
    super.dispose();
  }

  Future<void> _startTypewriterAnimations() async {
    // Small delay before starting top animation
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Start top text animation
    final topAnimationFuture = _animateText(_fullTopText, true);
    
    // Wait a bit longer before starting bottom animation
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Start bottom text animation (runs concurrently with top if top is still running)
    final bottomAnimationFuture = _animateText(_fullBottomText, false);
    
    // Wait for both animations to complete
    await Future.wait([topAnimationFuture, bottomAnimationFuture]);
    
    // Start pulse animations after typewriter animations complete
    _startPulseAnimations();
  }
  
  void _startPulseAnimations() {
    // Start top pulse animation
    _topPulseController.repeat(reverse: true);
    
    // Start bottom pulse animation with slight delay for visual variety
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _bottomPulseController.repeat(reverse: true);
      }
    });
  }

  Future<void> _animateText(String text, bool isTop) async {
    for (int i = 0; i <= text.length; i++) {
      if (mounted) {
        setState(() {
          if (isTop) {
            _displayedTopText = text.substring(0, i);
          } else {
            _displayedBottomText = text.substring(0, i);
          }
        });
        await Future.delayed(const Duration(milliseconds: 80));
      }
    }
  }

  void _navigateToAuth() {
    HapticFeedback.mediumImpact();
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top half - "I am ready" with cream background
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: _navigateToAuth,
                child: Container(
                  width: double.infinity,
                  color: _creamBackground,
                  child: Stack(
                    children: [
                      // Main content centered with pulse animation
                      Center(
                        child: _topPulseAnimation != null 
                          ? AnimatedBuilder(
                              animation: _topPulseAnimation!,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _topPulseAnimation!.value,
                                  child: Text(
                                    _displayedTopText,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: _brownText,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Text(
                              _displayedTopText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: _brownText,
                                letterSpacing: 1.2,
                              ),
                            ),
                      ),
                      // ">" icon in bottom-right corner
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Icon(
                          Icons.chevron_right,
                          size: 32,
                          color: _brownText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom half - "I am not ready yet" with brown background
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                color: _brownBackground,
                child: Center(
                  child: _bottomPulseAnimation != null
                    ? AnimatedBuilder(
                        animation: _bottomPulseAnimation!,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _bottomPulseAnimation!.value,
                            child: Text(
                              _displayedBottomText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: _creamText,
                                letterSpacing: 1.2,
                              ),
                            ),
                          );
                        },
                      )
                    : Text(
                        _displayedBottomText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: _creamText,
                          letterSpacing: 1.2,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
