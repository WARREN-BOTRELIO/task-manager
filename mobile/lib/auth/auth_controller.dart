import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../models/auth_response.dart';
import 'token_store.dart';

/// Session logic: login, register, restore and logout.
///
/// Listened to by the root widget, which switches between the login and the
/// tasks screens based on [isAuthenticated].
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthApi authApi,
    required TokenStore tokenStore,
    ApiClient? apiClient,
  })  : _authApi = authApi,
        _tokenStore = tokenStore {
    // Drop the session automatically whenever an API call is rejected with 401.
    apiClient?.onUnauthorized = logout;
    _ready = _restore();
  }

  final AuthApi _authApi;
  final TokenStore _tokenStore;

  Future<void>? _ready;

  /// Completes when the stored session has been restored (or found absent).
  Future<void> get ready => _ready ?? Future.value();

  bool _restoringSession = true;
  bool get restoringSession => _restoringSession;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String _email = '';
  String get email => _email;

  String? _token;
  String? get token => _token;

  Future<void> _restore() async {
    final storedToken = await _tokenStore.getToken();
    final storedEmail = await _tokenStore.getEmail();
    _token = (storedToken == null || storedToken.isEmpty) ? null : storedToken;
    _email = storedEmail ?? '';
    _isAuthenticated = _token != null;
    _restoringSession = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final auth = await _authApi.login(Credentials(email: email, password: password));
    await _applyAuth(auth);
  }

  Future<void> register(String email, String password) async {
    final auth = await _authApi.register(Credentials(email: email, password: password));
    await _applyAuth(auth);
  }

  Future<void> _applyAuth(AuthResponse auth) async {
    await _tokenStore.save(auth.token, auth.email);
    _token = auth.token;
    _email = auth.email;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _tokenStore.clear();
    _token = null;
    _email = '';
    _isAuthenticated = false;
    notifyListeners();
  }
}