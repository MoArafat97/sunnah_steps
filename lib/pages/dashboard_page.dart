// lib/pages/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_item.dart';
import '../data/sample_habits.dart';
import 'habit_library_page.dart';
import 'habit_detail_page.dart';
import '../widgets/today_checklist_overlay.dart';
import '../services/checklist_service.dart';
import '../services/progress_service.dart';
import '../services/firebase_service.dart';

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
  String _userName = "Assalamu 'Alaikum!"; // Default fallback

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
    // Load user name from Firebase
    _loadUserName();
    // Load synced habits from checklist
    _loadSyncedHabits();
    // Load progress data
    _loadProgressData();
    // Load pending recommendations count
    _loadPendingRecommendations();

    // Note: Checklist is now only shown from onboarding flow, not automatically on dashboard
    // Users can still access it manually from the drawer if needed
  }

  /// Refresh habit completions (useful for testing and when app resumes)
  Future<void> refreshHabitCompletions() async {
    print('Dashboard.refreshHabitCompletions: Refreshing habit completion status');
    try {
      final completions = await FirebaseService.getHabitCompletions();
      print('Dashboard.refreshHabitCompletions: Loaded ${completions.length} completions: $completions');

      setState(() {
        // Update completion status for existing habits
        for (final habit in _dailyHabits) {
          habit.completed = completions[habit.name] ?? false;
        }
        for (final habit in _weeklyHabits) {
          habit.completed = completions[habit.name] ?? false;
        }
      });

      print('Dashboard.refreshHabitCompletions: Updated habit completion status');
    } catch (e) {
      print('Dashboard.refreshHabitCompletions: Error refreshing completions - $e');
    }
  }

  /// Save completion to local storage as fallback
  Future<void> _saveCompletionToLocal(String habitName, bool isCompleted) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final key = 'habit_completion_${dateKey}_$habitName';

    await prefs.setBool(key, isCompleted);
    print('Dashboard._saveCompletionToLocal: Saved $habitName: $isCompleted to local storage with key $key');
  }

  /// Load completions from local storage
  Future<Map<String, bool>> _loadCompletionsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final completions = <String, bool>{};
    final allKeys = prefs.getKeys();

    for (final key in allKeys) {
      if (key.startsWith('habit_completion_$dateKey')) {
        final habitName = key.replaceFirst('habit_completion_${dateKey}_', '');
        final isCompleted = prefs.getBool(key) ?? false;
        completions[habitName] = isCompleted;
      }
    }

    print('Dashboard._loadCompletionsFromLocal: Loaded ${completions.length} completions from local storage: $completions');
    return completions;
  }

  /// Load user name from Firebase Auth or Firestore
  Future<void> _loadUserName() async {
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser != null) {
        // Try to get name from Firebase Auth displayName first
        String? userName = currentUser.displayName;

        // If no displayName, try to get from Firestore
        if (userName == null || userName.isEmpty) {
          final userDoc = await FirebaseService.firestore
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            userName = data['name'] ?? data['displayName'];
          }
        }

        // Update state with the found name or keep default
        if (userName != null && userName.isNotEmpty) {
          setState(() {
            _userName = userName!;
          });
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
      // Keep default fallback name
    }
  }

  /// Load habits from Firestore (primary) and local storage (fallback)
  Future<void> _loadSyncedHabits() async {
    print('Dashboard._loadSyncedHabits: Starting to load user habits');

    try {
      // Check authentication first
      final user = FirebaseService.currentUser;
      if (user == null) {
        print('Dashboard._loadSyncedHabits: No authenticated user, falling back to local storage');
        await _loadFromLocalStorage();
        return;
      }

      print('Dashboard._loadSyncedHabits: User authenticated (${user.uid}), loading from Firestore');

      // Try to load from Firestore first
      final firestoreHabits = await FirebaseService.getUserHabits();

      // If user has habits in Firestore, use those
      if (firestoreHabits['daily']!.isNotEmpty || firestoreHabits['weekly']!.isNotEmpty) {
        print('Dashboard._loadSyncedHabits: Found habits in Firestore - daily=${firestoreHabits['daily']?.length}, weekly=${firestoreHabits['weekly']?.length}');

        // Load habit completion status for today
        print('Dashboard._loadSyncedHabits: Loading completion status for today...');
        final completions = await FirebaseService.getHabitCompletions();
        print('Dashboard._loadSyncedHabits: Loaded ${completions.length} completions: $completions');

        setState(() {
          _dailyHabits = firestoreHabits['daily']!.map((name) =>
            HabitItem(name: name, completed: completions[name] ?? false)).toList();
          _weeklyHabits = firestoreHabits['weekly']!.map((name) =>
            HabitItem(name: name, completed: completions[name] ?? false)).toList();
        });

        print('Dashboard._loadSyncedHabits: Successfully loaded ${_dailyHabits.length} daily and ${_weeklyHabits.length} weekly habits');
        return;
      }

      // No habits in Firestore, fallback to local storage
      print('Dashboard._loadSyncedHabits: No habits in Firestore, falling back to local storage');
      await _loadFromLocalStorage();

    } catch (e) {
      print('Dashboard._loadSyncedHabits: Error loading from Firestore - $e');
      // Fallback to local storage on error
      await _loadFromLocalStorage();
    }
  }

  /// Load habits from local storage with completion status
  Future<void> _loadFromLocalStorage() async {
    try {
      final localHabits = await ChecklistService.instance.getSyncedDashboardHabits();
      print('Dashboard._loadFromLocalStorage: Loaded from local storage - daily=${localHabits['daily']?.length}, weekly=${localHabits['weekly']?.length}');

      // Try to load completions from Firestore first, then local storage
      Map<String, bool> completions = {};
      try {
        completions = await FirebaseService.getHabitCompletions();
        print('Dashboard._loadFromLocalStorage: Loaded ${completions.length} completions from Firestore');
      } catch (completionError) {
        print('Dashboard._loadFromLocalStorage: Could not load completions from Firestore - $completionError');
        // Fallback to local storage completions
        try {
          completions = await _loadCompletionsFromLocal();
          print('Dashboard._loadFromLocalStorage: Loaded ${completions.length} completions from local storage fallback');
        } catch (localError) {
          print('Dashboard._loadFromLocalStorage: Could not load completions from local storage either - $localError');
        }
      }

      setState(() {
        _dailyHabits = localHabits['daily']!.map((name) =>
          HabitItem(name: name, completed: completions[name] ?? false)).toList();
        _weeklyHabits = localHabits['weekly']!.map((name) =>
          HabitItem(name: name, completed: completions[name] ?? false)).toList();
      });

      // If we loaded from local storage and user is authenticated, sync to Firestore
      if ((localHabits['daily']!.isNotEmpty || localHabits['weekly']!.isNotEmpty) &&
          FirebaseService.currentUser != null) {
        print('Dashboard._loadFromLocalStorage: Syncing local habits to Firestore');
        await _syncHabitsToFirestore();
      }
    } catch (e) {
      print('Dashboard._loadFromLocalStorage: Error loading from local storage - $e');
      // Initialize with empty lists as last resort
      setState(() {
        _dailyHabits = [];
        _weeklyHabits = [];
      });
    }
  }

  /// Sync current habits to Firestore
  Future<void> _syncHabitsToFirestore() async {
    try {
      await FirebaseService.saveUserHabits(
        dailyHabits: _dailyHabits.map((h) => h.name).toList(),
        weeklyHabits: _weeklyHabits.map((h) => h.name).toList(),
      );
      print('Dashboard._syncHabitsToFirestore: synced habits to Firestore');
    } catch (e) {
      print('Dashboard._syncHabitsToFirestore: error syncing to Firestore - $e');
    }
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
    print('Dashboard._onHabitCompleted: ${habit.name} -> $isCompleted');

    // Add haptic feedback for better UX - use lightImpact for completion
    if (isCompleted) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }

    // Update local state immediately for smooth UX
    setState(() => habit.completed = isCompleted);

    // Save completion status to Firestore with comprehensive error handling
    try {
      // Check if user is authenticated first
      final user = FirebaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated - cannot save completion');
      }

      print('Dashboard._onHabitCompleted: User authenticated (${user.uid}), saving to Firestore...');

      await FirebaseService.saveHabitCompletion(
        habitName: habit.name,
        isCompleted: isCompleted,
      );

      print('Dashboard._onHabitCompleted: Successfully saved ${habit.name}: $isCompleted to Firestore');

      // Show success feedback for completion
      if (isCompleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${habit.name} saved successfully!'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }

    } catch (e) {
      print('Dashboard._onHabitCompleted: Error saving habit completion - $e');

      // Show error feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save ${habit.name}: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red.shade600,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _onHabitCompleted(habit, isCompleted),
            ),
          ),
        );
      }

      // Save to local storage as fallback
      try {
        await _saveCompletionToLocal(habit.name, isCompleted);
        print('Dashboard._onHabitCompleted: Saved to local storage as fallback');
      } catch (localError) {
        print('Dashboard._onHabitCompleted: Failed to save to local storage too - $localError');
      }

      // Don't revert state if we have local fallback
      return; // Don't proceed with other operations if Firestore save failed
    }

    if (isCompleted) {
      // Find the corresponding SunnahHabit to get the ID
      final sunnahHabit = sampleHabits.firstWhere(
        (h) => h.title == habit.name,
        orElse: () => sampleHabits.first, // fallback
      );

      // Record completion in progress service
      await ProgressService.instance.recordHabitCompletion(sunnahHabit.id);

      // Show completion message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Habit completed! BarakAllahu feekum 🌸'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Note: We keep completed habits in the list to maintain accurate progress tracking
      // The animation will show the completion state but habits remain for counting

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
              // Refresh button for testing habit persistence
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: refreshHabitCompletions,
                tooltip: 'Refresh Completions',
              ),
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
  child: SafeArea(
    child: SingleChildScrollView(
      child: Column(
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
      const Divider(),
      // Sign Out / Sign In
      _buildAuthTile(context),

      // Add bottom padding for safe area
      const SizedBox(height: 16),
        ],
      ),
    ),
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

      // Sync the updated habits to Firestore
      await _syncHabitsToFirestore();
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



  Widget _buildAuthTile(BuildContext context) {
    final currentUser = FirebaseService.currentUser;

    if (currentUser != null) {
      // User is signed in - show sign out option
      return ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Sign Out'),
        subtitle: Text('Signed in as: ${currentUser.email ?? currentUser.displayName ?? 'Unknown'}'),
        onTap: () => _signOut(context),
      );
    } else {
      // User is not signed in - show sign in option
      return ListTile(
        leading: const Icon(Icons.login, color: Colors.green),
        title: const Text('Sign In'),
        subtitle: const Text('Not signed in – Tap here to log in'),
        onTap: () {
          Navigator.pop(context); // Close drawer first
          context.go('/auth');
        },
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    Navigator.pop(context); // Close drawer first

    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await FirebaseService.signOut();

        // Clear only session-specific local flags (not onboarding completion)
        // Onboarding completion is now stored in Firestore and tied to user account
        // Local flags are kept for UI state consistency

        if (mounted) {
          context.go('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildBody() {
    if (_dailyHabits.isEmpty && _weeklyHabits.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Assalamu 'Alaikum, $_userName!",
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
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()
              ..translate(habit.completed ? 10.0 : 0.0, 0.0, 0.0),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: habit.completed ? 0.7 : 1.0,
              child: ListTile(
                title: Text(
                  habit.name,
                  style: TextStyle(
                    decoration: habit.completed ? TextDecoration.lineThrough : null,
                    color: habit.completed ? Colors.grey : null,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SEND TO FRIEND button
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.teal),
                      onPressed: () async {
                        HapticFeedback.selectionClick();
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
                        HapticFeedback.selectionClick();
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
                    AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: habit.completed ? 1.2 : 1.0,
                      child: IconButton(
                        icon: Icon(
                          habit.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: habit.completed ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => _onHabitCompleted(habit, !habit.completed),
                      ),
                    ),
                  ],
                ),
              ),
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