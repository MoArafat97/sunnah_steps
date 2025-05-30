import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/today_checklist_overlay.dart';
import '../../services/checklist_service.dart';

class MicroLessonScreen extends StatefulWidget {
  const MicroLessonScreen({super.key});

  @override
  State<MicroLessonScreen> createState() => _MicroLessonScreenState();
}

class _MicroLessonScreenState extends State<MicroLessonScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentPage = 0;
  final int _totalPages = 3;

  final List<MicroLesson> _lessons = [
    MicroLesson(
      icon: Icons.auto_awesome,
      title: "One small habit a day brings lasting barakah",
      subtitle: "Transform your life through the beautiful Sunnah",
      color: Colors.amber.shade400,
    ),
    MicroLesson(
      icon: Icons.favorite,
      title: "Following the Prophet ﷺ brings peace to the heart",
      subtitle: "Find tranquility in his blessed guidance",
      color: Colors.pink.shade400,
    ),
    MicroLesson(
      icon: Icons.trending_up,
      title: "Every Sunnah practiced is a step closer to Allah",
      subtitle: "Your spiritual journey starts with simple actions",
      color: Colors.green.shade400,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _currentPage++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Reset and replay animations
      _fadeController.reset();
      _slideController.reset();
      _fadeController.forward();
      _slideController.forward();
    } else {
      // Complete onboarding and show checklist
      _completeOnboarding();
    }
  }

  void _skipToQuestions() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    print('MicroLessonScreen._completeOnboarding: starting onboarding completion');

    // Mark onboarding as completed
    await ChecklistService.instance.markOnboardingCompleted();

    // Check if checklist should be shown after onboarding completion
    final shouldShow = await ChecklistService.instance.shouldShowChecklistAfterOnboarding();
    print('MicroLessonScreen._completeOnboarding: shouldShow=$shouldShow');

    if (shouldShow && mounted) {
      print('MicroLessonScreen._completeOnboarding: showing checklist overlay');
      // Show the checklist overlay
      await showTodayChecklistOverlay(
        context,
        onComplete: () async {
          print('MicroLessonScreen._completeOnboarding: checklist completed, marking post-onboarding as shown');
          // Mark post-onboarding checklist as shown (separate from daily logic)
          await ChecklistService.instance.markPostOnboardingChecklistShown();
          if (mounted) {
            context.go('/dashboard');
          }
        },
        onSkip: () async {
          print('MicroLessonScreen._completeOnboarding: checklist skipped, marking post-onboarding as shown');
          // Mark post-onboarding checklist as shown (separate from daily logic)
          await ChecklistService.instance.markPostOnboardingChecklistShown();
          if (mounted) {
            context.go('/dashboard');
          }
        },
      );
    } else {
      print('MicroLessonScreen._completeOnboarding: checklist not needed, going directly to dashboard');
      // Go directly to dashboard
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade50,
              Colors.white,
              Colors.teal.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _skipToQuestions,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.teal.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });

                    // Reset and replay animations
                    _fadeController.reset();
                    _slideController.reset();
                    _fadeController.forward();
                    _slideController.forward();
                  },
                  itemCount: _totalPages,
                  itemBuilder: (context, index) {
                    final lesson = _lessons[index];
                    return _buildLessonPage(lesson);
                  },
                ),
              ),

              // Page indicators and navigation
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _totalPages,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.teal
                                : Colors.teal.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Next/Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          _currentPage == _totalPages - 1
                              ? 'Complete Onboarding'
                              : 'Continue',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  Widget _buildLessonPage(MicroLesson lesson) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: lesson.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: lesson.color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  lesson.icon,
                  size: 60,
                  color: lesson.color,
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Main title
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                lesson.title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.teal.shade800,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Subtitle
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                lesson.subtitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MicroLesson {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  MicroLesson({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
