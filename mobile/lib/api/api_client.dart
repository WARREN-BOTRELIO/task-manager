import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_error.dart';

/// Supplies the current JWT (if any) for the `Authorization` header.
typedef TokenProvider = String? Function();

/// Thin HTTP wrapper around the Task Manager REST API.
///
/// Responsibilities:
///   - JSON (de)serialization of requests/responses;
///   - attaching the `Authorization: Bearer <token>` header;
///   - mapping non-2xx responses to [ApiException];
///   - firing [onUnauthorized] when a request is rejected with 401.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  TokenProvider? tokenProvider;

  /// Invoked whenever a request is rejected with HTTP 401.
  /// Wired to the auth controller so the session is dropped automatically.
  void Function()? onUnauthorized;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _send('GET', path, query: query);
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    final response = await _send('POST', path, body: body);
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    final response = await _send('PUT', path, body: body);
    return _decodeObject(response);
  }

  Future<void> deleteJson(String path) async {
    await _send('DELETE', path);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = _uri(path, query);
    final token = tokenProvider?.call();
    final headers = {
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final http.Response response;
    try {
      response = await switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(uri, headers: headers, body: _encode(body)),
        'PUT' => _client.put(uri, headers: headers, body: _encode(body)),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => throw ArgumentError('Unsupported HTTP method: $method'),
      }
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw const ApiException(
        'Unable to reach the server. Check your connection and API URL.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw const UnauthorizedException();
    }
    throw ApiException(_extractMessage(response), status: response.statusCode);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath').replace(queryParameters: query);
  }

  String? _encode(Object? body) {
    if (body == null) {
      return null;
    }
    return jsonEncode(body);
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const ApiException('Unexpected response from the server.');
  }

  String _extractMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return ApiError.fromJson(decoded).message;
      }
    } on FormatException {
      // Fall through to a generic message.
    }
    return 'Request failed (${response.statusCode}).';
  }
}