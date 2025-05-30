import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/animated_option_button.dart';

class AgeQuestionScreen extends StatelessWidget {
  const AgeQuestionScreen({super.key});

  final List<String> ageOptions = const [
    '0-18',
    '18-25',
    '25-40',
    '40-60',
    '60+',
  ];

  void _selectAge(BuildContext context, String ageGroup) {
    // Save answer to service
    OnboardingService().setAgeGroup(ageGroup);

    // Navigate to next screen
    context.go('/onboarding/closeness');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => context.go('/intro'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress indicator (optional)
              LinearProgressIndicator(
                value: 1 / 5, // 1 of 5 questions
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),

              const SizedBox(height: 32),

              // Question text with warmth
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Help us personalize your journey — ',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 18,
                      ),
                    ),
                    const TextSpan(
                      text: 'what\'s your age range?',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Supportive subtitle
              Text(
                'This helps us provide relevant guidance for your life stage.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Age options with animated buttons
              Expanded(
                child: ListView.builder(
                  itemCount: ageOptions.length,
                  itemBuilder: (context, index) {
                    final option = ageOptions[index];
                    return AnimatedOptionButton(
                      text: option,
                      onPressed: () => _selectAge(context, option),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
