import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_status.dart';
import 'status_badge.dart';

/// A single task row inside the tasks list.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onDelete});

  final Task task;
  final Future<void> Function(Task task)? onDelete;

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][
        local.month - 1];
    return '$month ${local.day}, ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = task.status == TaskStatus.done;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 22,
              color: done ? const Color(0xFF16A34A) : theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? theme.colorScheme.outline : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (task.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusBadge(status: task.status),
                      const SizedBox(width: 10),
                      Text(
                        'Created ${_formatDate(task.createdAt)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Delete ${task.title}',
                icon: const Icon(Icons.delete_outline, size: 20),
                color: theme.colorScheme.onSurfaceVariant,
                onPressed: () => onDelete!(task),
              ),
          ],
        ),
      ),
    );
  }
}