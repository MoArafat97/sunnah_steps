import 'package:flutter/material.dart';
import '../models/habit_goal.dart';
import '../models/habit_schedule.dart';

/// Widget for configuring habit goals
class GoalConfigWidget extends StatefulWidget {
  final HabitGoal? initialGoal;
  final String habitId;
  final HabitSchedule? schedule;
  final Function(HabitGoal?) onGoalChanged;

  const GoalConfigWidget({
    super.key,
    this.initialGoal,
    required this.habitId,
    this.schedule,
    required this.onGoalChanged,
  });

  @override
  State<GoalConfigWidget> createState() => _GoalConfigWidgetState();
}

class _GoalConfigWidgetState extends State<GoalConfigWidget> {
  bool _hasGoal = false;
  GoalType _goalType = GoalType.streak;
  int _targetCount = 30;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _notes;

  @override
  void initState() {
    super.initState();
    _initializeFromExisting();
  }

  void _initializeFromExisting() {
    if (widget.initialGoal != null) {
      final goal = widget.initialGoal!;
      _hasGoal = true;
      _goalType = goal.type;
      _targetCount = goal.targetCount;
      _startDate = goal.startDate;
      _endDate = goal.endDate;
      _notes = goal.notes;
    } else {
      _startDate = DateTime.now();
      _updateEndDateFromSchedule();
    }
  }

  void _updateEndDateFromSchedule() {
    if (widget.schedule != null && widget.schedule!.endDate != null) {
      _endDate = widget.schedule!.endDate;
    }
  }

  void _updateGoal() {
    if (!_hasGoal) {
      widget.onGoalChanged(null);
      return;
    }

    if (_startDate == null) return;

    final goal = HabitGoal(
      id: widget.initialGoal?.id ?? 'goal_${DateTime.now().millisecondsSinceEpoch}',
      habitId: widget.habitId,
      type: _goalType,
      targetCount: _targetCount,
      currentCount: widget.initialGoal?.currentCount ?? 0,
      startDate: _startDate!,
      endDate: _endDate,
      createdAt: widget.initialGoal?.createdAt ?? DateTime.now(),
      notes: _notes?.trim().isEmpty == true ? null : _notes?.trim(),
      metadata: _goalType == GoalType.frequency ? {'period': 'week'} : null,
    );

    widget.onGoalChanged(goal);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGoalToggle(),
        if (_hasGoal) ...[
          const SizedBox(height: 16),
          _buildGoalTypeSelector(),
          const SizedBox(height: 16),
          _buildTargetConfig(),
          const SizedBox(height: 16),
          _buildDateConfig(),
          const SizedBox(height: 16),
          _buildNotesField(),
        ],
      ],
    );
  }

  Widget _buildGoalToggle() {
    return Row(
      children: [
        Switch(
          value: _hasGoal,
          onChanged: (value) {
            setState(() {
              _hasGoal = value;
              _updateGoal();
            });
          },
          activeColor: Colors.teal.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          _hasGoal ? 'Goal Enabled' : 'No Goal',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildGoalTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Goal Type',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: GoalType.values.map((type) {
            return ChoiceChip(
              label: Text(_getGoalTypeLabel(type)),
              selected: _goalType == type,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _goalType = type;
                    _updateTargetForType();
                    _updateGoal();
                  });
                }
              },
              selectedColor: Colors.teal.shade100,
              labelStyle: TextStyle(
                color: _goalType == type ? Colors.teal.shade700 : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getGoalTypeDescription(_goalType),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target ${_getTargetLabel(_goalType)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: _targetCount.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (value) {
                  final count = int.tryParse(value);
                  if (count != null && count > 0) {
                    setState(() {
                      _targetCount = count;
                      _updateGoal();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(_getTargetUnit(_goalType)),
          ],
        ),
        if (_goalType == GoalType.streak && widget.schedule != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Schedule duration: ${widget.schedule!.getDaysRemaining()} days',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Goal Period',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Start Date',
                date: _startDate,
                onChanged: (date) {
                  setState(() {
                    _startDate = date;
                    _updateGoal();
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'End Date (Optional)',
                date: _endDate,
                onChanged: (date) {
                  setState(() {
                    _endDate = date;
                    _updateGoal();
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Select date',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Goal Notes (Optional)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _notes,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Add any notes about this goal...',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) {
            _notes = value;
            _updateGoal();
          },
        ),
      ],
    );
  }

  void _updateTargetForType() {
    switch (_goalType) {
      case GoalType.streak:
        _targetCount = widget.schedule?.getDaysRemaining() ?? 30;
        break;
      case GoalType.total:
        _targetCount = 50;
        break;
      case GoalType.frequency:
        _targetCount = 3;
        break;
    }
  }

  String _getGoalTypeLabel(GoalType type) {
    switch (type) {
      case GoalType.streak:
        return 'Streak';
      case GoalType.total:
        return 'Total Count';
      case GoalType.frequency:
        return 'Frequency';
    }
  }

  String _getGoalTypeDescription(GoalType type) {
    switch (type) {
      case GoalType.streak:
        return 'Complete the habit for consecutive days';
      case GoalType.total:
        return 'Complete the habit a total number of times';
      case GoalType.frequency:
        return 'Complete the habit a certain number of times per week';
    }
  }

  String _getTargetLabel(GoalType type) {
    switch (type) {
      case GoalType.streak:
        return 'Days';
      case GoalType.total:
        return 'Completions';
      case GoalType.frequency:
        return 'Times';
    }
  }

  String _getTargetUnit(GoalType type) {
    switch (type) {
      case GoalType.streak:
        return 'consecutive days';
      case GoalType.total:
        return 'total completions';
      case GoalType.frequency:
        return 'times per week';
    }
  }
}
