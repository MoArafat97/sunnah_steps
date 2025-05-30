import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';

class StruggleQuestionScreen extends StatelessWidget {
  const StruggleQuestionScreen({super.key});

  final List<String> struggleOptions = const [
    'Yes',
    'No',
  ];

  void _selectStruggle(BuildContext context, String struggle) {
    // Save answer to service
    OnboardingService().setStruggle(struggle.toLowerCase());

    // Navigate to appropriate frequency screen based on answer
    if (struggle.toLowerCase() == 'yes') {
      context.go('/onboarding/frequency_limited');
    } else {
      context.go('/onboarding/frequency_high');
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.teal),
            onPressed: () => context.go('/onboarding/closeness'),
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
                value: 3 / 5, // 3 of 5 questions
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),

              const SizedBox(height: 32),

              // Question text with empathetic copy
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
                      text: 'Everyone\'s journey is unique — ',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 18,
                      ),
                    ),
                    const TextSpan(
                      text: 'do you find it challenging to follow the Sunnah consistently?',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Supportive subtitle
              Text(
                'There\'s no judgment here, only understanding and support.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Struggle options
              Expanded(
                child: Column(
                  children: struggleOptions.map((option) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _selectStruggle(context, option),
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
