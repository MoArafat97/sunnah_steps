// lib/widgets/weekly_heatmap.dart

import 'package:flutter/material.dart';
import '../models/heatmap_data.dart';
import '../services/progress_service.dart';

/// Widget that displays a 7-day heatmap showing user habit engagement
class WeeklyHeatmap extends StatefulWidget {
  final WeeklyHeatmapData? heatmapData;
  final VoidCallback? onRefresh;

  const WeeklyHeatmap({
    Key? key,
    this.heatmapData,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<WeeklyHeatmap> createState() => _WeeklyHeatmapState();
}

class _WeeklyHeatmapState extends State<WeeklyHeatmap> {
  WeeklyHeatmapData? _heatmapData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  Future<void> _loadHeatmapData() async {
    if (widget.heatmapData != null) {
      setState(() {
        _heatmapData = widget.heatmapData;
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await ProgressService.instance.getWeeklyHeatmapData();
      setState(() {
        _heatmapData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading heatmap data: $e');
      setState(() {
        _heatmapData = WeeklyHeatmapData.currentWeek();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_heatmapData == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Unable to load heatmap data')),
      );
    }

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
          _buildHeader(),
          const SizedBox(height: 16),
          _buildHeatmapGrid(),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Week\'s Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_heatmapData!.totalCompletions} Sunnahs completed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        if (widget.onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              widget.onRefresh!();
              _loadHeatmapData();
            },
            color: Colors.grey[600],
          ),
      ],
    );
  }

  Widget _buildHeatmapGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _heatmapData!.days.map((dayData) => _buildDayCell(dayData)).toList(),
    );
  }

  Widget _buildDayCell(HeatmapData dayData) {
    final color = _getColorForIntensity(dayData.intensityLevel);
    final isToday = dayData.isToday;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _showDayDetails(dayData),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            children: [
              // Day name
              Text(
                dayData.dayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              
              // Heatmap cell
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: isToday 
                      ? Border.all(color: Colors.teal, width: 2)
                      : null,
                ),
                child: Center(
                  child: dayData.completionCount > 0
                      ? Text(
                          '${dayData.completionCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: dayData.intensityLevel >= 2 
                                ? Colors.white 
                                : Colors.grey[700],
                          ),
                        )
                      : null,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Day number
              Text(
                '${dayData.dayNumber}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForIntensity(int intensity) {
    switch (intensity) {
      case 0:
        return Colors.grey[200]!; // No completions
      case 1:
        return Colors.green[100]!; // 1 completion
      case 2:
        return Colors.green[300]!; // 2 completions
      case 3:
        return Colors.green[600]!; // 3+ completions
      default:
        return Colors.grey[200]!;
    }
  }

  Widget _buildLegend() {
    return Row(
      children: [
        Text(
          'Less',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        
        // Legend squares
        Row(
          children: [
            _buildLegendSquare(Colors.grey[200]!),
            const SizedBox(width: 2),
            _buildLegendSquare(Colors.green[100]!),
            const SizedBox(width: 2),
            _buildLegendSquare(Colors.green[300]!),
            const SizedBox(width: 2),
            _buildLegendSquare(Colors.green[600]!),
          ],
        ),
        
        const SizedBox(width: 8),
        Text(
          'More',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendSquare(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _showDayDetails(HeatmapData dayData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${dayData.dayName}, ${dayData.dayNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dayData.activityDescription,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (dayData.completionCount > 0) ...[
              const SizedBox(height: 12),
              const Text(
                'Completed Habits:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...dayData.completedHabitIds.map((habitId) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, 
                        size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getHabitTitle(habitId),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getHabitTitle(String habitId) {
    // This is a simplified version - in a real app, you'd look up the habit title
    // from your habits database or cache
    return 'Habit $habitId';
  }
}
