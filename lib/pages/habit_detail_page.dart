// lib/pages/habit_detail_page.dart

import 'package:flutter/material.dart';
import '../models/habit_item.dart';

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
      appBar: AppBar(title: Text(habit.name)),
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
          ],
        ),
      ),
    );
  }
}