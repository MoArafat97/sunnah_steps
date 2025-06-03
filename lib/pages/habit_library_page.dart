// lib/pages/habit_library_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/sample_habits.dart';
import '../models/habit_item.dart';
import '../theme/app_theme.dart';
import '../services/habit_scheduling_service.dart';

class HabitLibraryPage extends StatefulWidget {
  final List<String> preselectedDaily;
  final List<String> preselectedWeekly;

  const HabitLibraryPage({
    Key? key,
    required this.preselectedDaily,
    required this.preselectedWeekly,
  }) : super(key: key);

  @override
  State<HabitLibraryPage> createState() => _HabitLibraryPageState();
}

class _HabitLibraryPageState extends State<HabitLibraryPage> {
  List<HabitItem> _daily = [];
  List<HabitItem> _weekly = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _daily = sampleHabits
        .where((h) => h.category == 'daily')
        .map((h) => HabitItem(
              name: h.title,
              completed: widget.preselectedDaily.contains(h.title),
            ))
        .toList();
    _weekly = sampleHabits
        .where((h) => h.category == 'weekly')
        .map((h) => HabitItem(
              name: h.title,
              completed: widget.preselectedWeekly.contains(h.title),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = [..._daily, ..._weekly];
    final filtered = all
        .where((h) => h.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    final dFilt = filtered.where((h) => _daily.contains(h)).toList();
    final wFilt = filtered.where((h) => _weekly.contains(h)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop<List<List<String>>>(context, [
                _daily.where((h) => h.completed).map((h) => h.name).toList(),
                _weekly.where((h) => h.completed).map((h) => h.name).toList(),
              ]);
            },
          )
        ],
      ),
      body: AppTheme.backgroundContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Enhanced search field
            Container(
              decoration: AppTheme.enhancedCardDecoration,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Sunnah habits...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.primaryTeal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (t) => setState(() => _search = t),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  if (dFilt.isNotEmpty) ...[
                    _buildSectionHeader('Daily Habits', Icons.today),
                    const SizedBox(height: 12),
                    ...dFilt.map(_buildTile),
                    const SizedBox(height: 20),
                  ],
                  if (wFilt.isNotEmpty) ...[
                    _buildSectionHeader('Weekly Habits', Icons.calendar_view_week),
                    const SizedBox(height: 12),
                    ...wFilt.map(_buildTile),
                  ],
                  if (filtered.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.enhancedCardDecoration,
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppTheme.secondaryText,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No habits match your search',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try searching for different keywords',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppTheme.primaryTeal.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryTeal, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(HabitItem h) {
    // Find the corresponding SunnahHabit for scheduling functionality
    final sunnahHabit = sampleHabits.firstWhere(
      (habit) => habit.title == h.name,
      orElse: () => sampleHabits.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.enhancedCardDecoration,
      child: FutureBuilder<bool>(
        future: HabitSchedulingService.instance.isHabitScheduledForToday(sunnahHabit.id),
        builder: (context, snapshot) {
          final isScheduled = snapshot.data ?? false;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    h.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ),
                if (isScheduled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Scheduled',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: sunnahHabit.canBeScheduled
                ? Text(
                    'Long press to schedule',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sunnahHabit.canBeScheduled)
                  IconButton(
                    icon: Icon(
                      isScheduled ? Icons.schedule : Icons.schedule_outlined,
                      color: isScheduled ? Colors.teal.shade600 : Colors.grey.shade600,
                      size: 20,
                    ),
                    onPressed: () => _openScheduling(sunnahHabit),
                    tooltip: isScheduled ? 'Edit Schedule' : 'Create Schedule',
                  ),
                Switch(
                  value: h.completed,
                  onChanged: (v) => setState(() => h.completed = v),
                  activeColor: AppTheme.primaryTeal,
                ),
              ],
            ),
            onLongPress: sunnahHabit.canBeScheduled
                ? () => _openScheduling(sunnahHabit)
                : null,
          );
        },
      ),
    );
  }

  /// NEW - Open habit scheduling page
  Future<void> _openScheduling(dynamic sunnahHabit) async {
    try {
      final result = await context.push('/habit-scheduling/${sunnahHabit.id}');

      // Refresh the UI if scheduling was successful
      if (result == true && mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule updated for ${sunnahHabit.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening scheduling: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
