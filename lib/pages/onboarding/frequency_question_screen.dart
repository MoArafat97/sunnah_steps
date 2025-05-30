import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';

class FrequencyQuestionScreen extends StatelessWidget {
  const FrequencyQuestionScreen({super.key});

  final List<String> frequencyOptions = const [
    'Several times a day',
    'Once a day',
    'Once a week',
    'Once a month',
    'Rarely',
    'Never',
  ];

  void _selectFrequency(BuildContext context, String frequency) {
    // Save answer to service
    OnboardingService().setFrequency(frequency);
    
    // Navigate to next screen
    context.go('/onboarding/gender');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => context.go('/onboarding/struggle'),
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
                value: 4 / 5, // 4 of 5 questions
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
              
              const SizedBox(height: 32),
              
              // Question text
              Text(
                'How often do you follow the Sunnah?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Frequency options
              Expanded(
                child: ListView.builder(
                  itemCount: frequencyOptions.length,
                  itemBuilder: (context, index) {
                    final option = frequencyOptions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ElevatedButton(
                        onPressed: () => _selectFrequency(context, option),
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
