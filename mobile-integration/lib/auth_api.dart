import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    required this.imdbID,
    required this.username,
    required this.title,
    required this.status,
    required this.dateAdded,
    this.poster,
    this.userRating,
  });

  final String imdbID;
  final String username;
  final String title;
  final String status;
  final DateTime dateAdded;
  final String? poster;
  final double? userRating;

  factory FriendFeedItem.fromJson(Map<String, dynamic> json) {
    final String rawDate = json['dateAdded']?.toString() ?? '';
    final dynamic rawRating = json['userRating'];
    final double? parsedRating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating?.toString() ?? '');
    return FriendFeedItem(
      imdbID: json['imdbID']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      title: json['title']?.toString() ?? 'Untitled',
      status: json['status']?.toString() ?? 'watching',
      dateAdded: DateTime.tryParse(rawDate) ?? DateTime.now(),
      poster: json['poster']?.toString(),
      userRating: parsedRating,
    );
  }
}

class PublicUser {
  PublicUser({
    required this.id,
    required this.username,
    required this.profileVisibility,
    this.createdAt,
  });

  final String id;
  final String username;
  final String profileVisibility;
  final DateTime? createdAt;

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    final String rawCreatedAt = json['createdAt']?.toString() ?? '';
    return PublicUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown user',
      profileVisibility: json['profileVisibility']?.toString() ?? 'public',
      createdAt: DateTime.tryParse(rawCreatedAt),
    );
  }
}

class FriendUser {
  FriendUser({
    required this.id,
    required this.username,
    required this.profileVisibility,
  });

  final String id;
  final String username;
  final String profileVisibility;

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown user',
      profileVisibility: json['profileVisibility']?.toString() ?? 'public',
    );
  }
}

class RecommendedMovie {
  RecommendedMovie({
    required this.imdbID,
    required this.title,
    required this.year,
    required this.type,
    this.poster,
  });

  final String imdbID;
  final String title;
  final String year;
  final String type;
  final String? poster;

  factory RecommendedMovie.fromJson(Map<String, dynamic> json) {
    return RecommendedMovie(
      imdbID: json['imdbID']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      year: json['year']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      poster: json['poster']?.toString(),
    );
  }
}

class MediaDetail {
  MediaDetail({
    required this.imdbID,
    required this.title,
    required this.year,
    required this.type,
    required this.genres,
    required this.poster,
  });

  final String imdbID;
  final String title;
  final String year;
  final String type;
  final List<String> genres;
  final String poster;

  factory MediaDetail.fromJson(Map<String, dynamic> json) {
    final dynamic rawGenres = json['genres'];
    final List<String> genres = rawGenres is List
        ? rawGenres.map((dynamic value) => value.toString()).toList()
        : <String>[];

    return MediaDetail(
      imdbID: json['imdbID']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      year: json['year']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      genres: genres,
      poster: json['poster']?.toString() ?? '',
    );
  }
}

class WatchlistItem {
  WatchlistItem({
    required this.id,
    required this.imdbID,
    required this.status,
    required this.title,
    required this.poster,
    required this.isFavorite,
    required this.dateAdded,
    this.userRating,
  });

  final String id;
  final String imdbID;
  final String status;
  final String title;
  final String poster;
  final bool isFavorite;
  final DateTime dateAdded;
  final double? userRating;

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    final String rawDate = json['dateAdded']?.toString() ?? '';
    final dynamic rawRating = json['userRating'];
    final double? parsedRating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating?.toString() ?? '');
    return WatchlistItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      imdbID: json['imdbID']?.toString() ?? '',
      status: json['status']?.toString() ?? 'plan_to_watch',
      title: json['title']?.toString() ?? 'Untitled',
      poster: json['poster']?.toString() ?? '',
      isFavorite: json['isFavorite'] == true,
      dateAdded: DateTime.tryParse(rawDate) ?? DateTime.now(),
      userRating: parsedRating,
    );
  }

  WatchlistItem copyWith({
    String? status,
    String? title,
    String? poster,
    bool? isFavorite,
    DateTime? dateAdded,
    double? userRating,
  }) {
    return WatchlistItem(
      id: id,
      imdbID: imdbID,
      status: status ?? this.status,
      title: title ?? this.title,
      poster: poster ?? this.poster,
      isFavorite: isFavorite ?? this.isFavorite,
      dateAdded: dateAdded ?? this.dateAdded,
      userRating: userRating ?? this.userRating,
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
  static const String _localFavoritesKey = 'watchit_favorite_imdb_ids';

  static bool get _useLocalFavorites {
    // Always persist favorites locally.
    // Some backends may not persist/return `isFavorite` reliably, and the mobile
    // UX expects favorites to survive navigation/app restarts.
    return true;
  }

  static Future<Set<String>> _getLocalFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_localFavoritesKey) ?? <String>[])
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
  }

  static Future<void> setLocalFavorite({
    required String imdbID,
    required bool isFavorite,
  }) async {
    final String trimmed = imdbID.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<String> current =
        (prefs.getStringList(_localFavoritesKey) ?? <String>[])
            .map((String id) => id.trim())
            .where((String id) => id.isNotEmpty)
            .toSet();

    if (isFavorite) {
      current.add(trimmed);
    } else {
      current.remove(trimmed);
    }

    await prefs.setStringList(_localFavoritesKey, current.toList());
  }

  static const String _apiUrlFromEnv = String.fromEnvironment(
    'WATCHIT_API_URL',
  );
  static const String _prodBaseUrl = 'http://watch-it.xyz/api';
  static const String _mobileOrigin = 'http://watch-it.xyz';

  static String get baseUrl {
    final String resolved = _apiUrlFromEnv.isNotEmpty
        ? _normalizeBaseUrl(_apiUrlFromEnv)
        : _prodBaseUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final Uri uri = Uri.parse(resolved);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          return uri.replace(host: '10.0.2.2').toString();
        }
      } catch (_) {
        // Fall through to resolved.
      }
    }

    // Match the website backend/database by default in all build modes.
    return resolved;
  }

  static String _normalizeBaseUrl(String input) {
    final String trimmed = input.trim().replaceFirst(RegExp(r'/+$'), '');
    return trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
  }

  static Map<String, String> _headers({bool json = false, String? token}) {
    final Map<String, String> headers = <String, String>{};

    if (json) {
      headers['Content-Type'] = 'application/json';
    }

    // Work around deployed API CORS policy that currently expects website origin.
    // For local dev, omit Origin so the server can allow the request.
    if (!kIsWeb) {
      final String resolvedBaseUrl = baseUrl;
      if (resolvedBaseUrl.contains('watch-it.xyz')) {
        headers['Origin'] = _mobileOrigin;
      }
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static final Uri _registerUri = Uri.parse('$baseUrl/auth/register');
  static final Uri _loginUri = Uri.parse('$baseUrl/auth/login');
  static final Uri _profileUri = Uri.parse('$baseUrl/auth/profile');
  static final Uri _genrePreferencesUri = Uri.parse(
    '$baseUrl/auth/profile/preferences',
  );
  static final Uri _usersSearchUri = Uri.parse('$baseUrl/users/search');
  static final Uri _usersUri = Uri.parse('$baseUrl/users');
  static final Uri _friendsFeedUri = Uri.parse('$baseUrl/feed/friends');
  static final Uri _friendsUri = Uri.parse('$baseUrl/friends');
  static final Uri _mediaSearchUri = Uri.parse('$baseUrl/media/search');
  static final Uri _watchlistUri = Uri.parse('$baseUrl/watchlist');

  static Uri _watchlistItemUri(String id) =>
      Uri.parse('$baseUrl/watchlist/${Uri.encodeComponent(id)}');

  static Uri _friendUri(String id) =>
      Uri.parse('$baseUrl/friends/${Uri.encodeComponent(id)}');

  static Uri _publicUserUri(String userId) => _usersUri.replace(
    path: '${_usersUri.path}/${Uri.encodeComponent(userId)}',
  );

  static Uri _userWatchlistUri(String userId) => _watchlistUri.replace(
    path: '${_watchlistUri.path}/${Uri.encodeComponent(userId)}',
  );

  static Uri _mediaDetailUri(String imdbID) =>
      Uri.parse('$baseUrl/media/${Uri.encodeComponent(imdbID)}');

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
            headers: _headers(json: true, token: token),
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

  static Future<Map<String, dynamic>> fetchProfile() async {
    final String? token = AuthSession.authToken;
    if (token == null || token.isEmpty) {
      throw AuthApiException('You must be logged in to view your profile.');
    }

    try {
      final http.Response response = await http
          .get(_profileUri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> payload = _decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return payload;
      }

      final String backendMessage =
          payload['message']?.toString() ?? 'Failed to fetch profile.';
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

  static Future<Map<String, dynamic>> updateProfile({
    String? email,
    String? profileVisibility,
    String? introduction,
  }) async {
    final String? token = AuthSession.authToken;
    if (token == null || token.isEmpty) {
      throw AuthApiException('You must be logged in to update your profile.');
    }

    final Map<String, dynamic> body = <String, dynamic>{};
    if (email != null) {
      body['email'] = email.trim().toLowerCase();
    }
    if (profileVisibility != null) {
      body['profileVisibility'] = profileVisibility.trim().toLowerCase();
    }
    if (introduction != null) {
      body['introduction'] = introduction.trim();
    }

    if (body.isEmpty) {
      throw AuthApiException('No profile updates were provided.');
    }

    try {
      final http.Response response = await http
          .patch(
            _profileUri,
            headers: _headers(json: true, token: token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> payload = _decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic userPayload = payload['user'];
        if (userPayload is Map) {
          AuthSession.currentUser = Map<String, dynamic>.from(userPayload);
        }
        return payload;
      }

      final String backendMessage =
          payload['message']?.toString() ?? 'Failed to update profile.';
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

  static Future<List<PublicUser>> searchUsers(String query) async {
    final String trimmed = query.trim();
    if (trimmed.length < 2) {
      return <PublicUser>[];
    }

    try {
      final Uri uri = _usersSearchUri.replace(
        queryParameters: <String, String>{'query': trimmed},
      );
      final http.Response response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> payload = _decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic usersPayload = payload['users'];
        if (usersPayload is! List) {
          return <PublicUser>[];
        }

        return usersPayload
            .whereType<Map>()
            .map(
              (dynamic user) =>
                  PublicUser.fromJson(Map<String, dynamic>.from(user as Map)),
            )
            .toList();
      }

      final String backendMessage =
          payload['message']?.toString() ?? 'Failed to search users.';
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

  static Future<PublicUser> fetchPublicUser(String userId) async {
    final String trimmed = userId.trim();
    if (trimmed.isEmpty) {
      throw AuthApiException('Missing user id.');
    }

    try {
      final http.Response response = await http
          .get(_publicUserUri(trimmed), headers: _headers())
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> payload = _decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PublicUser.fromJson(payload);
      }

      final String backendMessage =
          payload['message']?.toString() ?? 'Failed to load user profile.';
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

  static Future<List<FriendUser>> fetchFriends() async {
    final String? token = AuthSession.authToken;
    if (token == null || token.isEmpty) {
      throw AuthApiException('You must be logged in to view your friends.');
    }

    try {
      final http.Response response = await http
          .get(_friendsUri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is! List) {
          return <FriendUser>[];
        }

        return decoded
            .whereType<Map>()
            .map(
              (dynamic user) =>
                  FriendUser.fromJson(Map<String, dynamic>.from(user as Map)),
            )
            .toList();
      }

      final Map<String, dynamic> payload = _decodeJson(response.body);
      final String backendMessage =
          payload['message']?.toString() ?? 'Failed to fetch friends.';
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

  static Future<void> followUser(String friendId) async {
    final String? token = AuthSession.authToken;
    if (token == null || token.isEmpty) {
      throw AuthApiException('You must be logged in to add friends.');
    }

    final String trimmed = friendId.trim();
    if (trimmed.isEmpty) {
      throw AuthApiException('Missing friend id.');
    }

    try {
      final http.Response response = await http
          .post(_friendUri(trimmed), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final Map<String, dynamic> payload = _decodeJson(response.body);
      final String backendMessage =
          payload['message']?.toString() ?? 'Failed to add friend.';
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

  static Future<void> unfollowUser(String friendId) async {
    final String? token = AuthSession.authToken;
    if (token == null || token.isEmpty) {
      throw AuthApiException('You must be logged in to update your friends.');
    }

    final String trimmed = friendId.trim();
    if (trimmed.isEmpty) {
      throw AuthApiException('Missing friend id.');
    }

    try {
      final http.Response response = await http
          .delete(_friendUri(trimmed), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final Map<String, dynamic> payload = _decodeJson(response.body);
      final String backendMessage =
          payload['message']?.toString() ?? 'Failed to remove friend.';
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
          .get(_friendsFeedUri, headers: _headers(token: token))
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

  static Future<List<RecommendedMovie>> searchMedia(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      return <RecommendedMovie>[];
    }

    final List<String> types = <String>['movie', 'series'];
    final Set<String> seenIds = <String>{};
    final List<RecommendedMovie> results = <RecommendedMovie>[];
    AuthApiException? lastError;

    for (final String type in types) {
      try {
        final Uri uri = _mediaSearchUri.replace(
          queryParameters: <String, String>{'title': trimmed, 'type': type},
        );

        final http.Response response = await http
            .get(uri, headers: _headers())
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 404) {
          continue;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          final Map<String, dynamic> payload = _decodeJson(response.body);
          final String message =
              payload['message']?.toString() ?? 'Failed to search media.';
          throw AuthApiException(message);
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
        }
      } on AuthApiException catch (error) {
        lastError = error;
      } on TimeoutException {
        lastError = AuthApiException(
          'Request timeout. Server is not responding.',
        );
      } catch (_) {
        lastError = AuthApiException(
          'Unable to connect to server. Please check your connection and try again.',
        );
      }
    }

    if (results.isEmpty && lastError != null) {
      throw lastError;
    }

    return results;
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

    const List<String> mediaTypes = <String>['movie', 'series'];

    for (final String genre in limitedGenres) {
      for (final String type in mediaTypes) {
        try {
          final Uri uri = _mediaSearchUri.replace(
            queryParameters: <String, String>{'title': genre, 'type': type},
          );

          final http.Response response = await http
              .get(uri, headers: _headers())
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

            if (results.length >= 12) {
              return results;
            }
          }
        } catch (_) {
          // Ignore per-genre lookup failures and continue building recommendations.
        }
      }
    }

    return results;
  }

  static Future<MediaDetail> fetchMediaDetail(String imdbID) async {
    final String trimmed = imdbID.trim();
    if (trimmed.isEmpty) {
      throw AuthApiException('Missing imdbID.');
    }

    try {
      final http.Response response = await http
          .get(_mediaDetailUri(trimmed), headers: _headers())
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> payload = _decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return MediaDetail.fromJson(payload);
      }

      final String backendMessage =
          payload['message']?.toString() ?? 'Failed to load media details.';
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

  static Future<List<WatchlistItem>> fetchMyWatchlist() async {
    final String? token = AuthSession.authToken;
    if (token == null || token.isEmpty) {
      throw AuthApiException('You must be logged in to view your watchlist.');
    }

    try {
      final http.Response response = await http
          .get(_watchlistUri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final Map<String, dynamic> payload = _decodeJson(response.body);
        final String backendMessage =
            payload['message']?.toString() ?? 'Failed to fetch watchlist.';
        throw AuthApiException(backendMessage);
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return <WatchlistItem>[];
      }

      final List<WatchlistItem> items = decoded
          .whereType<Map>()
          .map(
            (dynamic item) =>
                WatchlistItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      final Set<String> favorites = await _getLocalFavorites();
      if (favorites.isEmpty) {
        return items;
      }

      return items
          .map(
            (WatchlistItem item) => favorites.contains(item.imdbID)
                ? item.copyWith(isFavorite: true)
                : item,
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

  static Future<List<WatchlistItem>> fetchUserWatchlist(String userId) async {
    final String trimmed = userId.trim();
    if (trimmed.isEmpty) {
      throw AuthApiException('Missing user id.');
    }

    try {
      final http.Response response = await http
          .get(_userWatchlistUri(trimmed), headers: _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final Map<String, dynamic> payload = _decodeJson(response.body);
        final String backendMessage =
            payload['message']?.toString() ?? 'Failed to fetch watchlist.';
        throw AuthApiException(backendMessage);
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return <WatchlistItem>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (dynamic item) =>
                WatchlistItem.fromJson(Map<String, dynamic>.from(item as Map)),
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

  static Future<WatchlistItem> addToWatchlist({
    required String imdbID,
    String? title,
    String? poster,
    String status = 'plan_to_watch',
    bool? isFavorite,
  }) async {
    final String? token = AuthSession.authToken;
    if (token == null || token.isEmpty) {
      throw AuthApiException('You must be logged in to update your watchlist.');
    }

    final String trimmed = imdbID.trim();
    if (trimmed.isEmpty) {
      throw AuthApiException('Missing imdbID.');
    }

    try {
      final http.Response response = await http
          .post(
            _watchlistUri,
            headers: _headers(json: true, token: token),
            body: jsonEncode(<String, dynamic>{
              'imdbID': trimmed,
              'status': status,
              'title': ?title,
              'poster': ?poster,
              'isFavorite': ?isFavorite,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> payload = _decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = payload['data'];
        if (data is Map) {
          final WatchlistItem item = WatchlistItem.fromJson(
            Map<String, dynamic>.from(data),
          );
          if (isFavorite != null) {
            await setLocalFavorite(imdbID: item.imdbID, isFavorite: isFavorite);
          }
          return item;
        }
        throw AuthApiException('Added to watchlist.');
      }

      final String backendMessage =
          payload['message']?.toString() ?? 'Failed to add to watchlist.';
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

  static Future<void> deleteWatchlistItem(String id) async {
    final String? token = AuthSession.authToken;
    if (token == null || token.isEmpty) {
      throw AuthApiException('You must be logged in to update your watchlist.');
    }

    final String trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw AuthApiException('Missing watchlist item id.');
    }

    try {
      final http.Response response = await http
          .delete(_watchlistItemUri(trimmed), headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final Map<String, dynamic> payload = _decodeJson(response.body);
      final String backendMessage =
          payload['message']?.toString() ?? 'Failed to remove from watchlist.';
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

  static Future<WatchlistItem> updateWatchlistItem({
    required String id,
    String? status,
    double? userRating,
    bool? isFavorite,
  }) async {
    final String? token = AuthSession.authToken;
    if (token == null || token.isEmpty) {
      throw AuthApiException('You must be logged in to update your watchlist.');
    }

    final String trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw AuthApiException('Missing watchlist item id.');
    }

    final Map<String, dynamic> body = <String, dynamic>{};
    if (status != null) {
      body['status'] = status;
    }
    if (userRating != null) {
      body['userRating'] = userRating;
    }
    if (isFavorite != null) {
      body['isFavorite'] = isFavorite;
    }
    if (body.isEmpty) {
      throw AuthApiException('No watchlist updates were provided.');
    }

    try {
      if (kDebugMode) {
        print('🚀 Request: PUT ${_watchlistItemUri(trimmed)}');
        print('📤 Body: $body');
      }
      final http.Response response = await http
          .put(
            _watchlistItemUri(trimmed),
            headers: _headers(json: true, token: token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> payload = _decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print('✅ Success (${response.statusCode}): ${payload['message']}');
        }
        final dynamic data = payload['data'];
        if (data is Map) {
          final WatchlistItem item = WatchlistItem.fromJson(
            Map<String, dynamic>.from(data),
          );
          if (isFavorite != null) {
            await setLocalFavorite(imdbID: item.imdbID, isFavorite: isFavorite);
          }
          return item;
        }
        throw AuthApiException('Updated watchlist item.');
      }

      if (kDebugMode) {
        print('❌ Failed (${response.statusCode}): ${payload['message']}');
      }

      final String backendMessage =
          payload['message']?.toString() ?? 'Failed to update watchlist item.';
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
          .post(uri, headers: _headers(json: true), body: jsonEncode(body))
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
    } on SocketException {
      throw AuthApiException(
        'Network error. Please verify your API URL and internet connection.',
      );
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

    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return <String, dynamic>{
        'message': 'Server returned a non-JSON response.',
      };
    }

    return <String, dynamic>{};
  }
}
