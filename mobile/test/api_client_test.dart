import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager/api/api_client.dart';
import 'package:task_manager/api/auth_api.dart';
import 'package:task_manager/api/tasks_api.dart';
import 'package:task_manager/models/api_error.dart';
import 'package:task_manager/models/task_status.dart';

void main() {
  group('ApiClient + TasksApi', () {
    test('GET /api/tasks parses a PageResponse<Task>', () async {
      final client = ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/tasks');
          expect(request.url.queryParameters['status'], 'DONE');
          expect(request.url.queryParameters['page'], '0');
          return http.Response(
            jsonEncode({
              'content': [
                {
                  'id': 1,
                  'title': 'Write report',
                  'description': null,
                  'status': 'DONE',
                  'createdAt': '2026-09-19T10:00:00',
                  'updatedAt': '2026-09-19T10:00:00',
                },
              ],
              'page': 0,
              'size': 100,
              'totalElements': 1,
              'totalPages': 1,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final page = await TasksApi(client)
          .list(const TaskListParams(status: TaskStatus.done));

      expect(page.totalElements, 1);
      expect(page.content.single.title, 'Write report');
      expect(page.content.single.status, TaskStatus.done);
      expect(page.content.single.description, isNull);
    });

    test('POST /api/tasks sends the expected payload and maps the response', () async {
      final client = ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/tasks');
          expect(request.headers['authorization'], 'Bearer jwt-token');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {
            'title': 'Buy milk',
            'description': '2L',
            'status': 'TODO',
          });
          return http.Response(
            jsonEncode({
              'id': 7,
              'title': 'Buy milk',
              'description': '2L',
              'status': 'TODO',
              'createdAt': '2026-09-19T10:00:00',
              'updatedAt': '2026-09-19T10:00:00',
            }),
            201,
          );
        }),
      );
      client.tokenProvider = () => 'jwt-token';

      final task = await TasksApi(client).create(
        title: 'Buy milk',
        description: '2L',
        status: TaskStatus.todo,
      );

      expect(task.id, 7);
      expect(task.status, TaskStatus.todo);
    });

    test('DELETE /api/tasks/{id} is sent and 204 is tolerated', () async {
      final client = ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, '/api/tasks/42');
          return http.Response('', 204);
        }),
      );

      await expectLater(TasksApi(client).delete(42), completes);
    });
  });

  group('ApiClient + AuthApi', () {
    test('POST /api/auth/login parses AuthResponse', () async {
      final client = ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/login');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['email'], 'alice@example.com');
          return http.Response(
            jsonEncode({
              'token': 'jwt-token',
              'tokenType': 'Bearer',
              'expiresIn': 86400000,
              'email': 'alice@example.com',
            }),
            200,
          );
        }),
      );

      final auth = await AuthApi(client)
          .login(const Credentials(email: 'alice@example.com', password: 'password123'));

      expect(auth.token, 'jwt-token');
      expect(auth.email, 'alice@example.com');
      expect(auth.expiresIn, 86400000);
    });
  });

  group('Error handling', () {
    test('401 fires onUnauthorized and throws UnauthorizedException', () async {
      var unauthorizedCalls = 0;
      final client = ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient((_) async => http.Response('', 401)),
      )..onUnauthorized = () => unauthorizedCalls++;

      await expectLater(client.getJson('/api/tasks'), throwsA(isA<UnauthorizedException>()));
      expect(unauthorizedCalls, 1);
    });

    test('non-2xx surfaces the backend ApiError message', () async {
      final client = ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'status': 409,
              'error': 'Conflict',
              'message': 'An account with this email already exists',
              'path': '/api/auth/register',
            }),
            409,
          ),
        ),
      );

      await expectLater(
        client.postJson('/api/auth/register'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 409)
              .having((e) => e.message, 'message', contains('already exists')),
        ),
      );
    });

    test('network failures map to a friendly ApiException', () async {
      final client = ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient((_) async => throw http.ClientException('connection refused')),
      );

      await expectLater(
        client.getJson('/api/tasks'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('server'))),
      );
    });
  });
}