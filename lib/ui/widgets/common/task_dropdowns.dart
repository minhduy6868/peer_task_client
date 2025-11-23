import 'package:flutter/material.dart';

class StatusDropdown extends StatelessWidget {
  final String value;
  final Function(String?) onChanged;

  const StatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const Map<String, String> statuses = {
    'todo': 'To Do',
    'in_progress': 'In Progress',
    'done': 'Done',
    'blocked': 'Blocked',
  };

  static const Map<String, Color> statusColors = {
    'todo': Colors.grey,
    'in_progress': Colors.blue,
    'done': Colors.green,
    'blocked': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        prefixIcon: Icon(
          Icons.circle,
          color: statusColors[value] ?? Colors.grey,
          size: 16,
        ),
      ),
      items: statuses.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Row(
            children: [
              Icon(
                Icons.circle,
                color: statusColors[entry.key],
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(entry.value),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class PriorityDropdown extends StatelessWidget {
  final String value;
  final Function(String?) onChanged;

  const PriorityDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const Map<String, String> priorities = {
    'high': 'High',
    'medium': 'Medium',
    'low': 'Low',
  };

  static const Map<String, Color> priorityColors = {
    'high': Colors.red,
    'medium': Colors.orange,
    'low': Colors.green,
  };

  static const Map<String, IconData> priorityIcons = {
    'high': Icons.arrow_upward,
    'medium': Icons.remove,
    'low': Icons.arrow_downward,
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        prefixIcon: Icon(
          priorityIcons[value],
          color: priorityColors[value],
          size: 20,
        ),
      ),
      items: priorities.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Row(
            children: [
              Icon(
                priorityIcons[entry.key],
                color: priorityColors[entry.key],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(entry.value),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
