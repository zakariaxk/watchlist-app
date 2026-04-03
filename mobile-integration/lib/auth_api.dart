import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

class FriendFeedItem {
  FriendFeedItem({
    required this.username,
    required this.title,
    required this.status,
    required this.dateAdded,
    this.poster,
  });

  final String username;
  final String title;
  final String status;
  final DateTime dateAdded;
  final String? poster;

  factory FriendFeedItem.fromJson(Map<String, dynamic> json) {
    final String rawDate = json['dateAdded']?.toString() ?? '';
    return FriendFeedItem(
      username: json['username']?.toString() ?? 'Unknown',
      title: json['title']?.toString() ?? 'Untitled',
      status: json['status']?.toString() ?? 'watching',
      dateAdded: DateTime.tryParse(rawDate) ?? DateTime.now(),
      poster: json['poster']?.toString(),
    );
  }
}

class RecommendedMovie {
  RecommendedMovie({
    required this.imdbID,
    required this.title,
    required this.year,
    this.poster,
  });

  final String imdbID;
  final String title;
  final String year;
  final String? poster;

  factory RecommendedMovie.fromJson(Map<String, dynamic> json) {
    return RecommendedMovie(
      imdbID: json['imdbID']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      year: json['year']?.toString() ?? '',
      poster: json['poster']?.toString(),
    );
  }
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
  static const String baseUrl = 'http://192.241.131.53:5001/api';

  static final Uri _registerUri = Uri.parse('$baseUrl/auth/register');
  static final Uri _loginUri = Uri.parse('$baseUrl/auth/login');
  static final Uri _genrePreferencesUri = Uri.parse(
    '$baseUrl/auth/profile/preferences',
  );
  static final Uri _friendsFeedUri = Uri.parse('$baseUrl/feed/friends');
  static final Uri _mediaSearchUri = Uri.parse('$baseUrl/media/search');

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

  static Future<void> saveGenrePreferences(List<String> genres) async {
    final String? token = AuthSession.authToken;
    if (token == null || token.isEmpty) {
      throw AuthApiException('You must be logged in to save preferences.');
    }

    try {
      final http.Response response = await http
          .patch(
            _genrePreferencesUri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(<String, dynamic>{'genres': genres}),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> payload = _decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic userPayload = payload['user'];
        if (userPayload is Map) {
          AuthSession.currentUser = Map<String, dynamic>.from(userPayload);
        }
        return;
      }

      final String backendMessage =
          payload['message']?.toString() ??
          'Failed to save your genre preferences.';
      throw AuthApiException(backendMessage);
    } on AuthApiException {
      rethrow;
    } on TimeoutException {
      throw AuthApiException('Request timeout. Server is not responding.');
    } catch (_) {
      throw AuthApiException(
        'Unable to connect to server. Please check your connection and try again.',
      );
    }
  }

  static Future<List<FriendFeedItem>> fetchFriendsFeed() async {
    final String? token = AuthSession.authToken;
    if (token == null || token.isEmpty) {
      throw AuthApiException('You must be logged in to view your feed.');
    }

    try {
      final http.Response response = await http
          .get(
            _friendsFeedUri,
            headers: <String, String>{'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final Map<String, dynamic> payload = _decodeJson(response.body);
        final String message =
            payload['message']?.toString() ??
            'Failed to load your friends feed.';
        throw AuthApiException(message);
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return <FriendFeedItem>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (dynamic item) =>
                FriendFeedItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on AuthApiException {
      rethrow;
    } on TimeoutException {
      throw AuthApiException('Request timeout. Server is not responding.');
    } catch (_) {
      throw AuthApiException(
        'Unable to connect to server. Please check your connection and try again.',
      );
    }
  }

  static Future<List<RecommendedMovie>> fetchRecommendedMoviesByGenres(
    List<String> genres,
  ) async {
    if (genres.isEmpty) {
      return <RecommendedMovie>[];
    }

    final Set<String> seenIds = <String>{};
    final List<RecommendedMovie> results = <RecommendedMovie>[];
    final List<String> limitedGenres = genres
        .map((String genre) => genre.trim())
        .where((String genre) => genre.isNotEmpty)
        .take(3)
        .toList();

    for (final String genre in limitedGenres) {
      try {
        final Uri uri = _mediaSearchUri.replace(
          queryParameters: <String, String>{'title': genre, 'type': 'movie'},
        );

        final http.Response response = await http
            .get(uri)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode < 200 || response.statusCode >= 300) {
          continue;
        }

        final Map<String, dynamic> payload = _decodeJson(response.body);
        final dynamic rawResults = payload['results'];
        if (rawResults is! List) {
          continue;
        }

        for (final dynamic item in rawResults.whereType<Map>()) {
          final RecommendedMovie movie = RecommendedMovie.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          if (movie.imdbID.isEmpty || seenIds.contains(movie.imdbID)) {
            continue;
          }

          seenIds.add(movie.imdbID);
          results.add(movie);

          if (results.length >= 8) {
            return results;
          }
        }
      } catch (_) {
        // Ignore per-genre lookup failures and continue building recommendations.
      }
    }

    return results;
  }

  static Future<AuthResult> _postAuth(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    try {
      if (kDebugMode) {
        print('🚀 Request: POST $uri');
        print('📤 Body: $body');
      }
      final http.Response response = await http
          .post(
            uri,
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> payload = _decodeJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print('✅ Success (${response.statusCode}): ${payload['message']}');
          print('👤 User: ${payload['user']}');
        }
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

      // Parse backend error and provide user-friendly message
      final String backendMessage =
          payload['message']?.toString() ?? 'Request failed. Please try again.';
      if (kDebugMode) {
        print('⚠️ Error (${response.statusCode}): $backendMessage');
        print('📋 Response body: ${response.body}');
      }
      final String userFriendlyMessage = _parseErrorMessage(
        statusCode: response.statusCode,
        backendMessage: backendMessage,
      );

      throw AuthApiException(userFriendlyMessage);
    } on AuthApiException {
      rethrow;
    } on TimeoutException {
      if (kDebugMode) {
        print('⏱️ Timeout: Request took too long. Server may be down.');
      }
      throw AuthApiException('Request timeout. Server is not responding.');
    } catch (error) {
      // Catch network errors, etc.
      if (kDebugMode) {
        print('❌ Network Error: $error');
        print('🔗 Attempted URL: $uri');
      }
      throw AuthApiException(
        'Unable to connect to server. Please check your connection and try again.',
      );
    }
  }

  static String _parseErrorMessage({
    required int statusCode,
    required String backendMessage,
  }) {
    // Email verification required
    if (statusCode == 403 && backendMessage.contains('verify')) {
      return 'Please verify your email before logging in.';
    }

    // Invalid credentials - provide specific guidance
    if (statusCode == 401) {
      if (backendMessage.contains('Invalid')) {
        return 'User not found or password is incorrect. Please check your username and try again.';
      }
    }

    // Bad request - validation error
    if (statusCode == 400) {
      return backendMessage;
    }

    // Server errors
    if (statusCode >= 500) {
      return 'Server error. Please try again later.';
    }

    return backendMessage;
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
