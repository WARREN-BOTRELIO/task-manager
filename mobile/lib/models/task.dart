import 'task_status.dart';

/// Mirror of the backend `TaskResponse` record.
class Task {
  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Task.fromJson(Map<String, dynamic> json) {
    final description = json['description'] as String?;
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: (description == null || description.isEmpty) ? null : description,
      status: TaskStatus.fromWire(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Payload sent when creating a task (`TaskRequest` on the backend).
class TaskCreateRequest {
  const TaskCreateRequest({
    required this.title,
    this.description,
    required this.status,
  });

  final String title;
  final String? description;
  final TaskStatus status;

  Map<String, dynamic> toJson() => {
        'title': title,
        if (description != null && description!.isNotEmpty) 'description': description,
        'status': status.wire,
      };
}