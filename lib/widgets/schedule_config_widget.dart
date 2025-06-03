import 'package:flutter/material.dart';
import '../models/habit_schedule.dart';

/// Widget for configuring habit schedules
class ScheduleConfigWidget extends StatefulWidget {
  final HabitSchedule? initialSchedule;
  final List<String> suggestedDurations;
  final Function(HabitSchedule?) onScheduleChanged;

  const ScheduleConfigWidget({
    super.key,
    this.initialSchedule,
    this.suggestedDurations = const ["7 days", "30 days", "90 days"],
    required this.onScheduleChanged,
  });

  @override
  State<ScheduleConfigWidget> createState() => _ScheduleConfigWidgetState();
}

class _ScheduleConfigWidgetState extends State<ScheduleConfigWidget> {
  ScheduleType _selectedType = ScheduleType.duration;
  int _durationDays = 30;
  int _frequency = 1;
  SchedulePeriod _period = SchedulePeriod.day;
  List<int> _selectedWeekdays = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String? _notes;

  @override
  void initState() {
    super.initState();
    _initializeFromExisting();
  }

  void _initializeFromExisting() {
    if (widget.initialSchedule != null) {
      final schedule = widget.initialSchedule!;
      _selectedType = schedule.type;
      _durationDays = schedule.durationDays ?? 30;
      _frequency = schedule.frequency ?? 1;
      _period = schedule.period ?? SchedulePeriod.day;
      _selectedWeekdays = schedule.weekdays ?? [];
      _startDate = schedule.startDate;
      _endDate = schedule.endDate;
      _notes = schedule.notes;
    } else {
      _startDate = DateTime.now();
      _updateEndDate();
    }
  }

  void _updateEndDate() {
    if (_startDate != null && _selectedType == ScheduleType.duration) {
      _endDate = _startDate!.add(Duration(days: _durationDays - 1));
    }
  }

  void _updateSchedule() {
    if (_startDate == null) return;

    final schedule = HabitSchedule(
      id: widget.initialSchedule?.id ?? 'schedule_${DateTime.now().millisecondsSinceEpoch}',
      type: _selectedType,
      durationDays: _selectedType == ScheduleType.duration ? _durationDays : null,
      startDate: _startDate,
      endDate: _endDate,
      weekdays: _selectedType == ScheduleType.custom ? _selectedWeekdays : null,
      frequency: _selectedType == ScheduleType.frequency ? _frequency : null,
      period: _selectedType == ScheduleType.frequency ? _period : null,
      createdAt: widget.initialSchedule?.createdAt ?? DateTime.now(),
      notes: _notes?.trim().isEmpty == true ? null : _notes?.trim(),
    );

    widget.onScheduleChanged(schedule);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScheduleTypeSelector(),
        const SizedBox(height: 16),
        _buildScheduleConfiguration(),
        const SizedBox(height: 16),
        _buildDateSelectors(),
        const SizedBox(height: 16),
        _buildNotesField(),
      ],
    );
  }

  Widget _buildScheduleTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Type',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ScheduleType.values.map((type) {
            return ChoiceChip(
              label: Text(_getScheduleTypeLabel(type)),
              selected: _selectedType == type,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                    _updateEndDate();
                    _updateSchedule();
                  });
                }
              },
              selectedColor: Colors.teal.shade100,
              labelStyle: TextStyle(
                color: _selectedType == type ? Colors.teal.shade700 : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleConfiguration() {
    switch (_selectedType) {
      case ScheduleType.duration:
        return _buildDurationConfig();
      case ScheduleType.frequency:
        return _buildFrequencyConfig();
      case ScheduleType.custom:
        return _buildCustomConfig();
    }
  }

  Widget _buildDurationConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: widget.suggestedDurations.map((duration) {
            final days = _parseDurationToDays(duration);
            return ChoiceChip(
              label: Text(duration),
              selected: _durationDays == days,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _durationDays = days;
                    _updateEndDate();
                    _updateSchedule();
                  });
                }
              },
              selectedColor: Colors.teal.shade100,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Custom: '),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: _durationDays.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (value) {
                  final days = int.tryParse(value);
                  if (days != null && days > 0) {
                    setState(() {
                      _durationDays = days;
                      _updateEndDate();
                      _updateSchedule();
                    });
                  }
                },
              ),
            ),
            const Text(' days'),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _frequency.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (value) {
                  final freq = int.tryParse(value);
                  if (freq != null && freq > 0) {
                    setState(() {
                      _frequency = freq;
                      _updateSchedule();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('times per'),
            const SizedBox(width: 8),
            DropdownButton<SchedulePeriod>(
              value: _period,
              onChanged: (period) {
                if (period != null) {
                  setState(() {
                    _period = period;
                    _updateSchedule();
                  });
                }
              },
              items: SchedulePeriod.values.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period.name),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Days of the Week',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (int i = 1; i <= 7; i++)
              FilterChip(
                label: Text(_getWeekdayName(i)),
                selected: _selectedWeekdays.contains(i),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedWeekdays.add(i);
                    } else {
                      _selectedWeekdays.remove(i);
                    }
                    _selectedWeekdays.sort();
                    _updateSchedule();
                  });
                },
                selectedColor: Colors.teal.shade100,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
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
                    _updateEndDate();
                    _updateSchedule();
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'End Date',
                date: _endDate,
                onChanged: _selectedType == ScheduleType.duration
                    ? null // Auto-calculated for duration
                    : (date) {
                        setState(() {
                          _endDate = date;
                          _updateSchedule();
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
    required Function(DateTime?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onChanged != null
              ? () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    onChanged(picked);
                  }
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: onChanged == null ? Colors.grey.shade100 : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: onChanged == null ? Colors.grey : null,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Select date',
                  style: TextStyle(
                    color: onChanged == null ? Colors.grey : null,
                  ),
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
          'Notes (Optional)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _notes,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Add any notes about this schedule...',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) {
            _notes = value;
            _updateSchedule();
          },
        ),
      ],
    );
  }

  String _getScheduleTypeLabel(ScheduleType type) {
    switch (type) {
      case ScheduleType.duration:
        return 'Duration';
      case ScheduleType.frequency:
        return 'Frequency';
      case ScheduleType.custom:
        return 'Custom Days';
    }
  }

  String _getWeekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  int _parseDurationToDays(String duration) {
    final parts = duration.toLowerCase().split(' ');
    if (parts.length >= 2) {
      final number = int.tryParse(parts[0]) ?? 1;
      final unit = parts[1];
      
      if (unit.startsWith('day')) return number;
      if (unit.startsWith('week')) return number * 7;
      if (unit.startsWith('month')) return number * 30;
    }
    return 30; // Default
  }
}
