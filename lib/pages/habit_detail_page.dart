// lib/pages/habit_detail_page.dart

import 'package:flutter/material.dart';
import '../models/habit_item.dart';
import '../widgets/send_sunnah_dialog.dart';
import '../theme/app_theme.dart';

class HabitDetailPage extends StatelessWidget {
  final HabitItem habit;
  final String hadithEnglish;
  final String hadithArabic;
  final String benefits;

  const HabitDetailPage({
    Key? key,
    required this.habit,
    required this.hadithEnglish,
    required this.hadithArabic,
    required this.benefits,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            onPressed: () => _sendToFriend(context),
            icon: const Icon(Icons.share),
            tooltip: 'Send to Friend',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Why this Sunnah?",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(benefits),
            const SizedBox(height: 24),
            Text("Source (Hadith/Qur’an)",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(hadithEnglish),
            const SizedBox(height: 32),

            // Send to Friend button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _sendToFriend(context),
                icon: const Icon(Icons.share),
                label: const Text('Send to Friend'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendToFriend(BuildContext context) async {
    await showSendSunnahDialog(
      context,
      habitId: habit.name, // Using name as ID for now
      habitTitle: habit.name,
    );
  }
}