import 'package:flutter/material.dart';

import '../models/task_status.dart';

const Map<TaskStatus, Color> _statusColors = {
  TaskStatus.todo: Color(0xFF64748B), // slate-500
  TaskStatus.inProgress: Color(0xFF2563EB), // blue-600
  TaskStatus.done: Color(0xFF16A34A), // green-600
};

/// Small pill showing a task status (mirrors the frontend `StatusBadge`).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}