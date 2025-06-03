import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/user_flags_service.dart';

class ChecklistWelcomePage extends StatefulWidget {
  static const route = '/checklist-welcome';

  const ChecklistWelcomePage({super.key});

  @override
  State<ChecklistWelcomePage> createState() => _ChecklistWelcomePageState();
}

class _ChecklistWelcomePageState extends State<ChecklistWelcomePage> {
  Future<void> _goToDashboard({required bool showOverlay}) async {
    // Mark prompt as seen so it never appears again.
    await UserFlagsService.markChecklistPromptSeen();

    // Use GoRouter for consistent navigation
    if (mounted) {
      if (showOverlay) {
        // Navigate to dashboard with overlay parameter
        context.go('/dashboard?showChecklist=true');
      } else {
        // Navigate to dashboard without overlay
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎉  Welcome aboard!', style: textTheme.headlineMedium),
              const SizedBox(height: 24),
              Text(
                'Would you like to see today\'s Sunnah checklist you can follow?',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => _goToDashboard(showOverlay: false),
                    child: const Text('Maybe later'),
                  ),
                  FilledButton(
                    onPressed: () => _goToDashboard(showOverlay: true),
                    child: const Text('Show me now  ➔'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
