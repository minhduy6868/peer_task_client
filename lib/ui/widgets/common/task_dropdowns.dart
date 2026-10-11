import 'package:flutter/material.dart';

/// Modern SaaS UI Status Dropdown Component
class ModernStatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const ModernStatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      elevation: 6,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'todo',
          child: Row(
            children: [
              Icon(Icons.radio_button_unchecked, size: 16, color: Color(0xFF6B7280)),
              SizedBox(width: 8),
              Text('Not started', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'doing',
          child: Row(
            children: [
              Icon(Icons.pie_chart, size: 16, color: Color(0xFF0078D4)),
              SizedBox(width: 8),
              Text('In progress', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'done',
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF5B4AD4)),
              SizedBox(width: 8),
              Text('Completed', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Row(
          children: [
            Expanded(child: _renderCurrentValue(value)),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _renderCurrentValue(String status) {
    switch (status) {
      case 'done':
        return const Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF5B4AD4)),
            SizedBox(width: 8),
            Text('Completed', style: TextStyle(fontSize: 13)),
          ],
        );
      case 'doing':
      case 'in_progress':
        return const Row(
          children: [
            Icon(Icons.pie_chart, size: 16, color: Color(0xFF0078D4)),
            SizedBox(width: 8),
            Text('In progress', style: TextStyle(fontSize: 13)),
          ],
        );
      default:
        return const Row(
          children: [
            Icon(Icons.radio_button_unchecked, size: 16, color: Color(0xFF6B7280)),
            SizedBox(width: 8),
            Text('Not started', style: TextStyle(fontSize: 13)),
          ],
        );
    }
  }
}

/// Modern SaaS UI Priority Dropdown Component
class ModernPriorityDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const ModernPriorityDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      elevation: 6,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'urgent',
          child: Row(
            children: [
              Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text('Urgent', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'high',
          child: Row(
            children: [
              Icon(Icons.priority_high_rounded, size: 16, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text('Important', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'medium',
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Medium', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'low',
          child: Row(
            children: [
              Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Low', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Row(
          children: [
            Expanded(child: _renderCurrentValue(value)),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _renderCurrentValue(String prio) {
    switch (prio) {
      case 'urgent':
        return const Row(
          children: [
            Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Urgent', style: TextStyle(fontSize: 13)),
          ],
        );
      case 'high':
        return const Row(
          children: [
            Icon(Icons.priority_high_rounded, size: 16, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Important', style: TextStyle(fontSize: 13)),
          ],
        );
      case 'low':
        return const Row(
          children: [
            Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Low', style: TextStyle(fontSize: 13)),
          ],
        );
      default:
        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Medium', style: TextStyle(fontSize: 13)),
          ],
        );
    }
  }
}
