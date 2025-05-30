import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';
import '../../data/sunnah_norms.dart';
import 'dart:math' as math;

class RichComparisonScreen extends StatefulWidget {
  const RichComparisonScreen({super.key});

  @override
  State<RichComparisonScreen> createState() => _RichComparisonScreenState();
}

class _RichComparisonScreenState extends State<RichComparisonScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _userBarAnimation;
  late Animation<double> _peerBarAnimation;

  int userScore = 0;
  double peerScore = 0.0;
  String interpretation = '';

  @override
  void initState() {
    super.initState();
    _calculateScores();
    _setupAnimations();
  }

  void _calculateScores() {
    final userAnswers = OnboardingService().userAnswers;

    if (userAnswers.frequency != null) {
      userScore = getEngagementScore(userAnswers.frequency!);
    }

    if (userAnswers.ageGroup != null && userAnswers.gender != null) {
      peerScore = getPeerAverageEngagement(
        userAnswers.ageGroup!,
        userAnswers.gender!.toLowerCase(),
      );
    }

    // Calculate interpretation
    final difference = userScore - peerScore.round();
    if (difference > 0) {
      interpretation = 'You are ${difference.abs()}% above the average';
    } else if (difference < 0) {
      interpretation = 'You are ${difference.abs()}% below the average';
    } else {
      interpretation = 'You are exactly at the average';
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _userBarAnimation = Tween<double>(
      begin: 0.0,
      end: userScore / 100.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _peerBarAnimation = Tween<double>(
      begin: 0.0,
      end: peerScore / 100.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Placeholder for icon/illustration
              Container(
                height: 60,
                margin: const EdgeInsets.only(bottom: 24),
                child: Icon(
                  Icons.analytics_outlined,
                  size: 48,
                  color: Colors.teal.shade400,
                ),
              ),

              // Headline
              Text(
                'Your Sunnah Engagement vs. Peers',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Bar Chart Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Bar Chart
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 220,
                        minHeight: 180,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth - 48; // Account for padding
                          final barWidth = math.min(50.0, availableWidth / 3);
                          final spacing = math.min(40.0, availableWidth / 4);

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // User Bar
                              _buildAnimatedBar(
                                'You',
                                userScore,
                                Colors.indigo.shade600, // Changed to indigo
                                _userBarAnimation,
                                barWidth,
                              ),

                              SizedBox(width: spacing),

                              // Peer Bar
                              _buildAnimatedBar(
                                'Peers',
                                peerScore.round(),
                                Colors.amber.shade600, // Changed to amber
                                _peerBarAnimation,
                                barWidth,
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Interpretation
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Text(
                        interpretation,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.teal.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Statistical Disclaimer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '*This insight is a general statistical comparison against global Sunnah adherence data—not a measure of your personal commitment.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Continue Button
              ElevatedButton(
                onPressed: () {
                  context.go('/onboarding/micro-lessons');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBar(
    String label,
    int percentage,
    Color color,
    Animation<double> animation,
    double barWidth,
  ) {
    const double maxBarHeight = 140.0;

    return Flexible(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Percentage Label
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final currentValue = (animation.value * percentage).round();
              return Text(
                '$currentValue%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Animated Bar
          Container(
            width: barWidth,
            height: maxBarHeight,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(barWidth / 2),
            ),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final animatedHeight = maxBarHeight * animation.value * (percentage / 100);
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: barWidth,
                    height: animatedHeight,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(barWidth / 2),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
