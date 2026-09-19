# Task Manager — mobile (Flutter)

Flutter mobile client for the Task Manager platform. See the root [`README.md`](../README.md) for the
full monorepo documentation (backend, frontend, Docker, tests).

## Scope

- Login and registration against the Spring Boot REST API (JWT auth).
- List, search, filter and create tasks; delete tasks.
- Session persisted in the Android Keystore / iOS Keychain (`flutter_secure_storage`).

## Run

```sh
# The backend must be running (see root README).
# Android emulator (defaults to http://10.0.2.2:8080):
flutter run
# iOS simulator (host loopback is localhost):
flutter run --dart-define=API_BASE_URL=http://localhost:8080
# Physical device (LAN IP of the machine running the backend):
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080
```

## Structure

```text
lib/
  api/        HTTP communication (ApiClient, AuthApi, TasksApi)
  auth/       Session logic (AuthController, TokenStore)
  models/     Plain Dart models mirroring the backend DTOs
  screens/    Login / Register / Tasks screens (UI)
  widgets/    Reusable widgets (TaskCard, dialogs, badge…)
  config/     Build-time configuration (API base URL)
  main.dart   App wiring + lightweight DI
```

UI, logic and API communication are kept separate: screens never talk to HTTP
directly, they use `AuthController` and `TasksApi`.

## Tests

```sh
flutter analyze
flutter test
```

The suite covers the API client (parsing, error mapping, 401 handling), the auth
controller (login/register/restore/logout) and widget smoke tests.