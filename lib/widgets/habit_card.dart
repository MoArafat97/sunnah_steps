// lib/widgets/habit_card.dart

import 'package:flutter/material.dart';
import '../models/sunnah_habit.dart';

class HabitCard extends StatelessWidget {
  final SunnahHabit habit;
  final ValueChanged<bool> onReminderToggle;

  const HabitCard({
    Key? key,
    required this.habit,
    required this.onReminderToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(habit.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                Switch(
                  value: habit.reminder,
                  onChanged: onReminderToggle,
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Hadith
            Text(
              habit.hadithEnglish,
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6),

            // Benefits
            Text(
              habit.benefits,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
