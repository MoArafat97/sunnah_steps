// lib/pages/progress_page.dart

import 'package:flutter/material.dart';
import '../models/streak_data.dart';
import '../models/heatmap_data.dart';
import '../services/progress_service.dart';
import '../services/debug_service.dart';
import '../widgets/weekly_heatmap.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  StreakData? _streakData;
  WeeklyHeatmapData? _heatmapData;
  Map<String, dynamic>? _progressSummary;
  bool _isLoading = true;
  bool _isDebugMode = false;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
    _checkDebugMode();
  }

  Future<void> _loadProgressData() async {
    setState(() => _isLoading = true);

    try {
      final streakData = await ProgressService.instance.getStreakData();
      final heatmapData = await ProgressService.instance.getWeeklyHeatmapData();
      final progressSummary = await ProgressService.instance.getProgressSummary();

      setState(() {
        _streakData = streakData;
        _heatmapData = heatmapData;
        _progressSummary = progressSummary;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkDebugMode() async {
    final isDebug = await DebugService.instance.isDebugModeEnabled();
    setState(() => _isDebugMode = isDebug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Progress"),
        actions: [
          if (_isDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _showDebugPanel,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProgressData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStreakCard(),
                    const SizedBox(height: 16),
                    _buildHeatmapCard(),
                    const SizedBox(height: 16),
                    _buildStatsCard(),
                    const SizedBox(height: 16),
                    _buildInsightsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStreakCard() {
    if (_streakData == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _streakData!.streakEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    '${_streakData!.currentStreak}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Day Streak',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _streakData!.statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_streakData!.longestStreak > _streakData!.currentStreak) ...[
            const SizedBox(height: 8),
            Text(
              'Personal best: ${_streakData!.longestStreak} days',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeatmapCard() {
    return WeeklyHeatmap(
      heatmapData: _heatmapData,
      onRefresh: _loadProgressData,
    );
  }

  Widget _buildStatsCard() {
    if (_progressSummary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Today',
                  '${_progressSummary!['todayCompletions']}',
                  'Sunnahs',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'This Week',
                  '${_progressSummary!['weeklyTotal']}',
                  'Total',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Daily Avg',
                  '${(_progressSummary!['weeklyAverage'] as double).toStringAsFixed(1)}',
                  'Sunnahs',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard() {
    if (_heatmapData == null) return const SizedBox.shrink();

    final mostActiveDay = _heatmapData!.mostActiveDay;
    final totalCompletions = _heatmapData!.totalCompletions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (totalCompletions > 0) ...[
            _buildInsightItem(
              Icons.trending_up,
              'Most Active Day',
              mostActiveDay != null
                  ? '${mostActiveDay.dayName} (${mostActiveDay.completionCount} Sunnahs)'
                  : 'No data available',
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildInsightItem(
              Icons.calendar_today,
              'Consistency',
              _getConsistencyMessage(),
              Colors.blue,
            ),
          ] else ...[
            _buildInsightItem(
              Icons.info_outline,
              'Getting Started',
              'Complete your first Sunnah to see insights here!',
              Colors.grey,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String title, String description, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getConsistencyMessage() {
    if (_heatmapData == null) return 'No data available';

    final daysWithCompletions = _heatmapData!.days.where((day) => day.completionCount > 0).length;
    final consistencyPercentage = (daysWithCompletions / 7 * 100).round();

    if (consistencyPercentage >= 80) {
      return 'Excellent! $consistencyPercentage% of days active';
    } else if (consistencyPercentage >= 60) {
      return 'Good progress! $consistencyPercentage% of days active';
    } else if (consistencyPercentage >= 40) {
      return 'Building momentum! $consistencyPercentage% of days active';
    } else {
      return 'Room to grow! $consistencyPercentage% of days active';
    }
  }

  void _showDebugPanel() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Debug Panel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset Progress Data'),
              onTap: () async {
                await ProgressService.instance.resetAllProgress();
                Navigator.pop(context);
                _loadProgressData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_usage),
              title: const Text('Load Test Data'),
              onTap: () async {
                await DebugService.instance.enableTestDriveMode();
                Navigator.pop(context);
                _loadProgressData();
              },
            ),
          ],
        ),
      ),
    );
  }
}