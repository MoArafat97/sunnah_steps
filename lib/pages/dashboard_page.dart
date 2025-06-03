// lib/pages/dashboard_page.dart

import 'package:flutter/material.dart';
import '../models/habit_item.dart';
import '../data/sample_habits.dart';
import 'habit_library_page.dart';
import 'habit_detail_page.dart';
import '../widgets/today_checklist_overlay.dart';
import '../services/checklist_service.dart';
import '../services/progress_service.dart';
import '../models/streak_data.dart';
import '../services/sunnah_coaching_service.dart';
import '../pages/inbox_page.dart';
import '../widgets/send_sunnah_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key, this.initialChecklistOverlayVisible = false}) : super(key: key);

  final bool initialChecklistOverlayVisible;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final String userName = "Aisha Zaman";

  // Persisted lists of HabitItems
  List<HabitItem> _dailyHabits = [];
  List<HabitItem> _weeklyHabits = [];

  // Progress tracking
  StreakData? _streakData;
  int _todayCompletions = 0;
  int _pendingRecommendations = 0;

  // Checklist overlay visibility
  late bool _showChecklist = widget.initialChecklistOverlayVisible;

  // Compute progress
  int get totalDaily => _dailyHabits.length;
  int get doneDaily => _dailyHabits.where((h) => h.completed).length;
  double get progDaily => totalDaily > 0 ? doneDaily / totalDaily : 0;

  int get totalWeekly => _weeklyHabits.length;
  int get doneWeekly => _weeklyHabits.where((h) => h.completed).length;
  double get progWeekly => totalWeekly > 0 ? doneWeekly / totalWeekly : 0;

  @override
  void initState() {
    super.initState();
    // Load synced habits from checklist
    _loadSyncedHabits();
    // Load progress data
    _loadProgressData();
    // Load pending recommendations count
    _loadPendingRecommendations();

    // Note: Checklist is now only shown from onboarding flow, not automatically on dashboard
    // Users can still access it manually from the drawer if needed
  }

  /// Load habits that were synced from the checklist
  Future<void> _loadSyncedHabits() async {
    print('Dashboard._loadSyncedHabits: loading synced habits');
    final syncedHabits = await ChecklistService.instance.getSyncedDashboardHabits();

    print('Dashboard._loadSyncedHabits: received daily=${syncedHabits['daily']?.length}, weekly=${syncedHabits['weekly']?.length}');

    setState(() {
      // Merge synced habits with existing ones
      final existingDailyNames = _dailyHabits.map((h) => h.name).toSet();
      final existingWeeklyNames = _weeklyHabits.map((h) => h.name).toSet();

      print('Dashboard._loadSyncedHabits: existing daily=${existingDailyNames.length}, weekly=${existingWeeklyNames.length}');

      // Add new daily habits from checklist
      for (final habitName in syncedHabits['daily']!) {
        if (!existingDailyNames.contains(habitName)) {
          print('Dashboard._loadSyncedHabits: adding daily habit "$habitName"');
          _dailyHabits.add(HabitItem(name: habitName, completed: false));
        }
      }

      // Add new weekly habits from checklist
      for (final habitName in syncedHabits['weekly']!) {
        if (!existingWeeklyNames.contains(habitName)) {
          print('Dashboard._loadSyncedHabits: adding weekly habit "$habitName"');
          _weeklyHabits.add(HabitItem(name: habitName, completed: false));
        }
      }

      print('Dashboard._loadSyncedHabits: final daily=${_dailyHabits.length}, weekly=${_weeklyHabits.length}');
    });
  }

  /// Load progress data for display
  Future<void> _loadProgressData() async {
    try {
      final streakData = await ProgressService.instance.getStreakData();
      final todayCompletions = await ProgressService.instance.getTodayCompletionCount();

      setState(() {
        _streakData = streakData;
        _todayCompletions = todayCompletions;
      });
    } catch (e) {
      print('Error loading progress data: $e');
    }
  }

  // Debug mode functionality removed for production

  /// Load pending recommendations count
  Future<void> _loadPendingRecommendations() async {
    try {
      final count = await SunnahCoachingService.instance.getPendingRecommendationsCount();
      setState(() {
        _pendingRecommendations = count;
      });
    } catch (e) {
      print('Error loading pending recommendations: $e');
    }
  }

  /// Handle habit completion with progress tracking
  Future<void> _onHabitCompleted(HabitItem habit, bool isCompleted) async {
    setState(() => habit.completed = isCompleted);

    if (isCompleted) {
      // Find the corresponding SunnahHabit to get the ID
      final sunnahHabit = sampleHabits.firstWhere(
        (h) => h.title == habit.name,
        orElse: () => sampleHabits.first, // fallback
      );

      // Record completion in progress service
      await ProgressService.instance.recordHabitCompletion(sunnahHabit.id);

      // Reload progress data to update UI
      await _loadProgressData();

      print('Dashboard: Recorded completion for ${habit.name}');
    }
  }

  Future<void> _checkAndShowChecklist() async {
    final shouldShow = await ChecklistService.instance.shouldShowChecklist();

    if (shouldShow && mounted) {
      // Small delay to ensure the dashboard is fully loaded
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await showTodayChecklistOverlay(
          context,
          onComplete: () {
            // Checklist completed, reload synced habits
            _loadSyncedHabits();
          },
          onSkip: () {
            // Checklist skipped, stay on dashboard
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Sunnah Steps"),
            actions: [
              // Debug panel removed for production
            ],
          ),
          drawer: _buildDrawer(context),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildBody(),
          ),
        ),
        if (_showChecklist)
          TodayChecklistOverlay(
            onComplete: () {
              setState(() => _showChecklist = false);
              _loadSyncedHabits();
            },
            onSkip: () {
              setState(() => _showChecklist = false);
            },
          ),
      ],
    );
  }

Widget _buildDrawer(BuildContext context) => Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      const DrawerHeader(
        decoration: BoxDecoration(color: Colors.teal),
        child: Text('Sunnah Steps', style: TextStyle(color: Colors.white, fontSize: 24)),
      ),

      ListTile(
        leading: const Icon(Icons.home),
        title: const Text('Dashboard'),
        onTap: () => Navigator.pop(context),
      ),
      ListTile(
        leading: const Icon(Icons.list),
        title: const Text('Habit Library'),
        onTap: () => _openLibrary(context),
      ),
      ListTile(
        leading: const Icon(Icons.checklist_rtl),
        title: const Text('Today\'s Checklist'),
        onTap: () => _showTodaysChecklist(context),
      ),
      ListTile(
        leading: Stack(
          children: [
            const Icon(Icons.inbox),
            if (_pendingRecommendations > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$_pendingRecommendations',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: const Text('Sunnah Inbox'),
        onTap: () => _openInbox(context),
      ),
      ListTile(
        leading: const Icon(Icons.show_chart),
        title: const Text('Progress'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/progress');
        },
      ),
      const Divider(),
      // User Settings
      ListTile(
        leading: const Icon(Icons.refresh, color: Colors.blue),
        title: const Text('Refresh Checklist'),
        subtitle: const Text('Reset today\'s checklist to show again'),
        onTap: () => _showRefreshChecklistDialog(context),
      ),
      ListTile(
        leading: const Icon(Icons.restart_alt, color: Colors.orange),
        title: const Text('Reset My Progress'),
        subtitle: const Text('Clear all habit progress and start fresh'),
        onTap: () => _showResetProgressDialog(context),
      ),
    ],
  ),
);



  Future<void> _openLibrary(BuildContext context) async {
    final res = await Navigator.push<List<List<String>>>(
      context,
      MaterialPageRoute(
        builder: (_) => HabitLibraryPage(
          preselectedDaily: _dailyHabits.map((h) => h.name).toList(),
          preselectedWeekly: _weeklyHabits.map((h) => h.name).toList(),
        ),
      ),
    );
    if (res != null && res.length == 2) {
      setState(() {
        _dailyHabits = res[0].map((n) => HabitItem(name: n)).toList();
        _weeklyHabits = res[1].map((n) => HabitItem(name: n)).toList();
      });
    }
  }

  Future<void> _showTodaysChecklist(BuildContext context) async {
    Navigator.pop(context); // Close drawer first

    await showTodayChecklistOverlay(
      context,
      onComplete: () {
        // Checklist completed, reload synced habits
        _loadSyncedHabits();
      },
      onSkip: () {
        // Checklist skipped, stay on dashboard
      },
    );
  }

  Future<void> _openInbox(BuildContext context) async {
    Navigator.pop(context); // Close drawer first

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InboxPage()),
    );

    // Reload pending recommendations count when returning
    _loadPendingRecommendations();
  }

  Widget _buildBody() {
    if (_dailyHabits.isEmpty && _weeklyHabits.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Assalamu 'Alaikum, $userName!",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Progress summary card
        if (_streakData != null) _buildProgressSummary(),
        const SizedBox(height: 16),

        if (totalDaily > 0)
          _statCard("Daily Habits Completed", "$doneDaily / $totalDaily", progDaily),
        const SizedBox(height: 16),
        if (totalWeekly > 0)
          _statCard("Weekly Sunnahs Completed", "$doneWeekly / $totalWeekly", progWeekly),
        const SizedBox(height: 24),
        const Text("Today's Sunnah Checklist",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildChecklist("Daily Habits", _dailyHabits),
        const SizedBox(height: 16),
        _buildChecklist("Weekly Sunnahs", _weeklyHabits),
      ],
    );
  }

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          child: Column(children: [
            const Icon(Icons.info_outline, size: 72, color: Colors.teal),
            const SizedBox(height: 16),
            const Text("No habits selected yet.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "Tap the menu icon (≡) or the button below to choose your Sunnah habits.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text("Open Habit Library"),
              onPressed: () => _openLibrary(context),
            ),
          ]),
        ),
      );

  Widget _statCard(String title, String value, double ratio, {String? subtitle}) =>
      Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: ratio),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
        ),
      );

Widget _buildChecklist(String title, List<HabitItem> items) {
  if (items.isEmpty) return Text("No $title added.");
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (ctx, i) {
          final habit = items[i];
          return ListTile(
            title: Text(habit.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SEND TO FRIEND button
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.teal),
                  onPressed: () async {
                    await showSendSunnahDialog(
                      context,
                      habitId: habit.name,
                      habitTitle: habit.name,
                    );
                  },
                  tooltip: 'Send to Friend',
                ),

                // INFO button
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blueGrey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HabitDetailPage(
                          habit: habit,
                          // you can look up the hadith & benefits from your sample_habits by name:
                          hadithEnglish: sampleHabits.firstWhere((h) => h.title == habit.name).hadithEnglish,
                          hadithArabic: sampleHabits.firstWhere((h) => h.title == habit.name).hadithArabic,
                          benefits: sampleHabits.firstWhere((h) => h.title == habit.name).benefits,
                        ),
                      ),
                    );
                  },
                ),

                // COMPLETE toggle
                IconButton(
                  icon: Icon(
                    habit.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: habit.completed ? Colors.green : Colors.grey,
                  ),
                  onPressed: () => _onHabitCompleted(habit, !habit.completed),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

  /// Build progress summary card
  Widget _buildProgressSummary() {
    if (_streakData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.teal.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          // Streak info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _streakData!.streakEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_streakData!.currentStreak} Day Streak',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _streakData!.statusMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Today's count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '$_todayCompletions',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog for refreshing checklist
  Future<void> _showRefreshChecklistDialog(BuildContext context) async {
    Navigator.pop(context); // Close drawer first

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refresh Checklist'),
        content: const Text(
          'This will reset today\'s checklist so it appears again. '
          'Your progress and completed habits will not be affected.\n\n'
          'Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ChecklistService.instance.forceResetChecklistState();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Checklist refreshed! It will show again when needed.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Show confirmation dialog for resetting all progress
  Future<void> _showResetProgressDialog(BuildContext context) async {
    Navigator.pop(context); // Close drawer first

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Progress'),
        content: const Text(
          '⚠️ WARNING: This will permanently delete:\n\n'
          '• All your habit progress\n'
          '• Your streak data\n'
          '• Completed habit history\n'
          '• Today\'s checklist selections\n\n'
          'Your received Sunnah recommendations in the Inbox will NOT be affected.\n\n'
          'This action cannot be undone. Are you sure?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Resetting progress...'),
            ],
          ),
        ),
      );

      try {
        // Clear all progress data but preserve inbox
        await ChecklistService.instance.clearAllData();
        await ProgressService.instance.resetAllProgress();

        // Reset UI state
        setState(() {
          _dailyHabits.clear();
          _weeklyHabits.clear();
          _streakData = null;
          _todayCompletions = 0;
        });

        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 All progress has been reset. Start your journey fresh!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error resetting progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}