import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager/api/api_client.dart';
import 'package:task_manager/api/auth_api.dart';
import 'package:task_manager/auth/auth_controller.dart';
import 'package:task_manager/auth/token_store.dart';
import 'package:task_manager/models/api_error.dart';
import 'package:task_manager/models/auth_response.dart';

/// AuthApi that never hits the network.
class FakeAuthApi extends AuthApi {
  FakeAuthApi({this.failWith}) : super(ApiClient(baseUrl: 'http://test'));

  final ApiException? failWith;
  final List<String> loginAttempts = [];

  @override
  Future<AuthResponse> login(Credentials credentials) async {
    loginAttempts.add(credentials.email);
    final failure = failWith;
    if (failure != null) {
      throw failure;
    }
    return const AuthResponse(
      token: 'jwt-token',
      tokenType: 'Bearer',
      expiresIn: 86400000,
      email: 'alice@example.com',
    );
  }

  @override
  Future<AuthResponse> register(Credentials credentials) async => const AuthResponse(
        token: 'jwt-token',
        tokenType: 'Bearer',
        expiresIn: 86400000,
        email: 'alice@example.com',
      );
}

void main() {
  late InMemoryTokenStore store;

  setUp(() {
    store = InMemoryTokenStore();
  });

  AuthController buildController(AuthApi api, {ApiClient? client}) {
    final c = AuthController(authApi: api, tokenStore: store, apiClient: client);
    return c;
  }

  test('login stores the token and switches to authenticated', () async {
    final controller = buildController(FakeAuthApi(), client: ApiClient(baseUrl: 'http://test'));
    await controller.ready;

    await controller.login('alice@example.com', 'password123');

    expect(controller.isAuthenticated, isTrue);
    expect(controller.email, 'alice@example.com');
    expect(controller.token, 'jwt-token');
    expect(await store.getToken(), 'jwt-token');
    expect(await store.getEmail(), 'alice@example.com');
  });

  test('rejected login throws and leaves the session untouched', () async {
    final controller = buildController(
      FakeAuthApi(failWith: const ApiException('Invalid email or password', status: 401)),
      client: ApiClient(baseUrl: 'http://test'),
    );
    await controller.ready;

    await expectLater(
      controller.login('alice@example.com', 'bad-password'),
      throwsA(isA<ApiException>()),
    );
    expect(controller.isAuthenticated, isFalse);
    expect(await store.getToken(), isNull);
  });

  test('register authenticates the user', () async {
    final controller = buildController(FakeAuthApi(), client: ApiClient(baseUrl: 'http://test'));
    await controller.ready;

    await controller.register('alice@example.com', 'password123');

    expect(controller.isAuthenticated, isTrue);
    expect(await store.getEmail(), 'alice@example.com');
  });

  test('stored session is restored on startup', () async {
    await store.save('stored-token', 'bob@example.com');
    final controller = buildController(FakeAuthApi(), client: ApiClient(baseUrl: 'http://test'));

    await controller.ready;

    expect(controller.isAuthenticated, isTrue);
    expect(controller.token, 'stored-token');
    expect(controller.email, 'bob@example.com');
  });

  test('logout clears the token and storage', () async {
    await store.save('stored-token', 'bob@example.com');
    final controller = buildController(FakeAuthApi(), client: ApiClient(baseUrl: 'http://test'));
    await controller.ready;
    expect(controller.isAuthenticated, isTrue);

    await controller.logout();

    expect(controller.isAuthenticated, isFalse);
    expect(controller.email, isEmpty);
    expect(await store.getToken(), isNull);
  });

  test('a 401 from any API call logs the user out automatically', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((_) async => http.Response('', 401)),
    );
    final controller = buildController(FakeAuthApi(), client: client);
    await controller.ready;
    await controller.login('alice@example.com', 'password123');
    expect(controller.isAuthenticated, isTrue);

    await expectLater(client.getJson('/api/tasks'), throwsA(isA<UnauthorizedException>()));
    // onUnauthorized fires the logout without awaiting it; give it a turn.
    await pumpEventQueue();
    expect(controller.isAuthenticated, isFalse);
    expect(await store.getToken(), isNull);
  });
}