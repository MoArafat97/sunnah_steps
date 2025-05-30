import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';

class GenderQuestionScreen extends StatelessWidget {
  const GenderQuestionScreen({super.key});

  final List<String> genderOptions = const [
    'Male',
    'Female',
  ];

  void _selectGender(BuildContext context, String gender) {
    // Save answer to service
    OnboardingService().setGender(gender);

    // Navigate to rich comparison screen
    context.go('/onboarding/comparison');
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.teal),
            onPressed: () {
              // Navigate back to appropriate frequency screen based on struggle answer
              final userAnswers = OnboardingService().userAnswers;
              if (userAnswers.struggle == 'yes') {
                context.go('/onboarding/frequency_limited');
              } else {
                context.go('/onboarding/frequency_high');
              }
            },
          ),
        ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: 5 / 5, // 5 of 5 questions
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),

              const SizedBox(height: 32),

              // Question text
              Text(
                'What is your gender?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Gender options
              Expanded(
                child: Column(
                  children: genderOptions.map((option) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _selectGender(context, option),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.teal.shade300),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
