import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'api/tasks_api.dart';
import 'auth/auth_controller.dart';
import 'auth/token_store.dart';
import 'config/app_config.dart';
import 'screens/login_screen.dart';
import 'screens/tasks_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies();
  runApp(TaskManagerApp(dependencies: dependencies));
}

/// Aggregates the shared objects of the app (hand-rolled, lightweight DI).
///
/// `tokenStore` and `httpClient` are overridable so tests can inject an
/// in-memory store and a mock HTTP client.
class AppDependencies {
  AppDependencies({TokenStore? tokenStore, http.Client? httpClient, String? baseUrl}) {
    this.tokenStore = tokenStore ?? SecureTokenStore();
    apiClient = ApiClient(baseUrl: baseUrl ?? AppConfig.apiBaseUrl, client: httpClient);
    authApi = AuthApi(apiClient);
    tasksApi = TasksApi(apiClient);
    authController = AuthController(
      authApi: authApi,
      tokenStore: this.tokenStore,
      apiClient: apiClient,
    );
    // The token provider reads the in-memory session (never the cache on every call).
    apiClient.tokenProvider = () => authController.token;
  }

  late final TokenStore tokenStore;
  late final ApiClient apiClient;
  late final AuthApi authApi;
  late final TasksApi tasksApi;
  late final AuthController authController;
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: dependencies.authController,
        builder: (context, _) {
          final auth = dependencies.authController;
          // Briefly shown while the persisted session is restored.
          if (auth.restoringSession) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (!auth.isAuthenticated) {
            return LoginScreen(dependencies: dependencies);
          }
          return TasksScreen(dependencies: dependencies);
        },
      ),
    );
  }
}