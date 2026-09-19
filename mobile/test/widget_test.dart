import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager/auth/token_store.dart';
import 'package:task_manager/main.dart';

void main() {
  testWidgets('shows the login screen when no session is stored', (tester) async {
    final dependencies = AppDependencies(
      tokenStore: InMemoryTokenStore(),
      httpClient: MockClient((_) async => http.Response('', 500)),
    );

    await tester.pumpWidget(TaskManagerApp(dependencies: dependencies));
    // Wait for the session restore to complete and the screen to build.
    await tester.pump();
    await tester.pump();

    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Task Manager'), findsOneWidget);
  });

  testWidgets('shows the tasks screen and renders tasks when a session exists',
      (tester) async {
    final store = InMemoryTokenStore()
      ..token = 'jwt-token'
      ..email = 'alice@example.com';
    final dependencies = AppDependencies(
      tokenStore: store,
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/tasks') {
          return http.Response(
            jsonEncode({
              'content': [
                {
                  'id': 1,
                  'title': 'Write report',
                  'description': 'Quarterly summary',
                  'status': 'TODO',
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
        }
        return http.Response('', 404);
      }),
    );

    await tester.pumpWidget(TaskManagerApp(dependencies: dependencies));
    await tester.pump(); // session restore
    await tester.pump(); // tasks list request resolves
    await tester.pump();

    expect(find.text('My tasks'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('alice@example.com'), findsOneWidget);
  });

  testWidgets('discards the session when the API returns 401', (tester) async {
    final store = InMemoryTokenStore()
      ..token = 'expired-token'
      ..email = 'alice@example.com';
    final dependencies = AppDependencies(
      tokenStore: store,
      httpClient: MockClient((_) async => http.Response('', 401)),
    );

    await tester.pumpWidget(TaskManagerApp(dependencies: dependencies));
    await tester.pump(); // session restore
    await tester.pump(); // 401 handled → logged out
    await tester.pump();

    expect(dependencies.authController.isAuthenticated, isFalse);
    expect(find.text('Log in'), findsOneWidget);
  });
}