import '../models/page_response.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import 'api_client.dart';

/// Query parameters for `GET /api/tasks`.
class TaskListParams {
  const TaskListParams({
    this.status,
    this.search,
    this.page = 0,
    this.size = 100,
  });

  final TaskStatus? status;
  final String? search;
  final int page;
  final int size;

  Map<String, String> toQuery() {
    final status = this.status;
    final search = this.search;
    return {
      if (status != null) 'status': status.wire,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': '$page',
      'size': '$size',
    };
  }
}

/// Communication layer for the tasks endpoints:
///   - `GET /api/tasks`
///   - `POST /api/tasks`
///   - `DELETE /api/tasks/{id}`
class TasksApi {
  TasksApi(this._client);

  final ApiClient _client;

  Future<PageResponse<Task>> list([TaskListParams params = const TaskListParams()]) async {
    final json = await _client.getJson('/api/tasks', query: params.toQuery());
    return PageResponse.fromJson(json, Task.fromJson);
  }

  Future<Task> create({
    required String title,
    String? description,
    required TaskStatus status,
  }) async {
    final json = await _client.postJson(
      '/api/tasks',
      body: TaskCreateRequest(title: title, description: description, status: status).toJson(),
    );
    return Task.fromJson(json);
  }

  Future<void> delete(int id) async {
    await _client.deleteJson('/api/tasks/$id');
  }
}