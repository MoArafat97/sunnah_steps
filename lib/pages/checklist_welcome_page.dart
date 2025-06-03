import 'package:flutter/material.dart';
import '../services/user_flags_service.dart';
import 'dashboard_page.dart';

class ChecklistWelcomePage extends StatelessWidget {
  static const route = '/checklist-welcome';

  const ChecklistWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Future<void> _goToDashboard({required bool showOverlay}) async {
      // Mark prompt as seen so it never appears again.
      await UserFlagsService.markChecklistPromptSeen();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            // Pass a flag so Dashboard can immediately show the overlay.
            initialChecklistOverlayVisible: showOverlay,
          ),
        ),
      );
    }

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
