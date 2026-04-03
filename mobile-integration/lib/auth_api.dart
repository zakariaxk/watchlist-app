import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthResult {
  AuthResult({required this.message, required this.user, required this.token});

  final String message;
  final Map<String, dynamic> user;
  final String token;
}

class AuthSession {
  static Map<String, dynamic>? currentUser;
  static String? authToken;

  static void setSession({
    required Map<String, dynamic> user,
    required String token,
  }) {
    currentUser = user;
    authToken = token;
  }

  static void clear() {
    currentUser = null;
    authToken = null;
  }
}

class AuthApi {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://poosdproject.space:5001/api',
  );

  static final Uri _registerUri = Uri.parse('$baseUrl/auth/register');
  static final Uri _loginUri = Uri.parse('$baseUrl/auth/login');

  static Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) {
    return _postAuth(_registerUri, <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
    });
  }

  static Future<AuthResult> login({
    required String username,
    required String password,
  }) {
    return _postAuth(_loginUri, <String, dynamic>{
      'username': username,
      'password': password,
    });
  }

  static Future<AuthResult> _postAuth(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    final http.Response response = await http
        .post(
          uri,
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    final Map<String, dynamic> payload = _decodeJson(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> user = Map<String, dynamic>.from(
        payload['user'] as Map? ?? <String, dynamic>{},
      );
      final String token = payload['token']?.toString() ?? '';

      if (token.isEmpty) {
        throw AuthApiException('The server did not return an auth token.');
      }

      return AuthResult(
        message: payload['message']?.toString() ?? 'Success',
        user: user,
        token: token,
      );
    }

    throw AuthApiException(
      payload['message']?.toString() ?? 'Request failed. Please try again.',
    );
  }

  static Map<String, dynamic> _decodeJson(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{};
  }
}
