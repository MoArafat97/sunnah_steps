import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/sunnah_habit.dart';
import '../models/habit_schedule.dart';
import '../models/habit_goal.dart';
import '../services/habit_scheduling_service.dart';
import '../widgets/schedule_config_widget.dart';
import '../widgets/goal_config_widget.dart';

/// Page for configuring custom habit schedules and goals
class HabitSchedulingPage extends StatefulWidget {
  final SunnahHabit habit;
  final HabitSchedule? existingSchedule;
  final HabitGoal? existingGoal;

  const HabitSchedulingPage({
    super.key,
    required this.habit,
    this.existingSchedule,
    this.existingGoal,
  });

  @override
  State<HabitSchedulingPage> createState() => _HabitSchedulingPageState();
}

class _HabitSchedulingPageState extends State<HabitSchedulingPage> {
  HabitSchedule? _schedule;
  HabitGoal? _goal;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _schedule = widget.existingSchedule;
    _goal = widget.existingGoal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule ${widget.habit.title}'),
        backgroundColor: Colors.teal.shade50,
        foregroundColor: Colors.teal.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHabitInfo(),
                  const SizedBox(height: 24),
                  _buildScheduleSection(),
                  const SizedBox(height: 24),
                  _buildGoalSection(),
                  const SizedBox(height: 32),
                  if (_errorMessage != null) _buildErrorMessage(),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildHabitInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.habit.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.habit.benefits,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.habit.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Colors.teal.shade50,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.teal.shade700,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.teal.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Schedule Configuration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ScheduleConfigWidget(
              initialSchedule: _schedule,
              suggestedDurations: widget.habit.schedulingDurations,
              onScheduleChanged: (schedule) {
                setState(() {
                  _schedule = schedule;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Colors.teal.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Goal Configuration (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GoalConfigWidget(
              initialGoal: _goal,
              habitId: widget.habit.id,
              schedule: _schedule,
              onGoalChanged: (goal) {
                setState(() {
                  _goal = goal;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _schedule != null ? _saveSchedule : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Save Schedule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.existingSchedule != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _removeSchedule,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Remove Schedule',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSchedule() async {
    if (_schedule == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await HabitSchedulingService.instance.scheduleHabit(
        widget.habit.id,
        _schedule!,
        goal: _goal,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule saved for ${widget.habit.title}'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeSchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await HabitSchedulingService.instance.removeSchedule(widget.habit.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule removed for ${widget.habit.title}'),
            backgroundColor: Colors.orange,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
