import 'dart:async';

import 'package:flutter/material.dart';

import '../../auth_api.dart';
import '../media/media_detail_page.dart';
import '../profile/curation_page.dart';

class MainFeedPage extends StatefulWidget {
  const MainFeedPage({super.key});

  @override
  State<MainFeedPage> createState() => _MainFeedPageState();
}

class _MainFeedPageState extends State<MainFeedPage> {
  bool _isLoading = true;
  String? _error;
  List<FriendFeedItem> _feedItems = <FriendFeedItem>[];
  List<RecommendedMovie> _recommendedMovies = <RecommendedMovie>[];

  void _openDiscover() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _DiscoverPage()));
  }

  void _openMyProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CurationPage(saveOnNext: false)),
    );
  }

  void _logout() {
    AuthSession.clear();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _openSearch() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _MediaSearchPage()));
  }

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<FriendFeedItem> items = await AuthApi.fetchFriendsFeed();
      List<RecommendedMovie> recommendations = <RecommendedMovie>[];

      if (items.isEmpty) {
        final dynamic rawGenres = AuthSession.currentUser?['preferredGenres'];
        final List<String> genres = rawGenres is List
            ? rawGenres.map((dynamic value) => value.toString()).toList()
            : <String>[];

        recommendations = await AuthApi.fetchRecommendedMoviesByGenres(genres);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _feedItems = items;
        _recommendedMovies = recommendations;
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Could not load feed right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String username =
        AuthSession.currentUser?['username']?.toString() ?? 'User';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                PopupMenuButton<String>(
                  tooltip: 'User menu',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 120),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: const Icon(
                      Icons.menu,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                  onSelected: (String value) {
                    if (value == 'profile') {
                      _openMyProfile();
                      return;
                    }
                    if (value == 'logout') {
                      _logout();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'profile',
                          child: Text('My Profile'),
                        ),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Text('Log Out'),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : _feedItems.isEmpty
            ? ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 160),
                      child: ElevatedButton(
                        onPressed: _openDiscover,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                        ),
                        child: const Text('Discover'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Friends Feed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Nothing to see here yet...',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  const Text(
                    'Recommended for you',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_recommendedMovies.isEmpty)
                    const Text(
                      'Select genres to start getting picks.',
                      style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                    )
                  else
                    ..._recommendedMovies.map(
                      (RecommendedMovie movie) =>
                          _RecommendationCard(movie: movie),
                    ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 160),
                      child: ElevatedButton(
                        onPressed: _openDiscover,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                        ),
                        child: const Text('Discover'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Friends Feed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...() {
                    final List<Widget> items = <Widget>[];
                    for (int i = 0; i < _feedItems.length; i++) {
                      items.add(_FeedStatusCard(item: _feedItems[i]));
                      if (i != _feedItems.length - 1) {
                        items.add(const SizedBox(height: 12));
                      }
                    }
                    return items;
                  }(),
                ],
              ),
      ),
    );
  }
}

class _MediaSearchPage extends StatefulWidget {
  const _MediaSearchPage();

  @override
  State<_MediaSearchPage> createState() => _MediaSearchPageState();
}

class _MediaSearchPageState extends State<_MediaSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearching = false;
  String? _searchError;
  List<RecommendedMovie> _searchResults = <RecommendedMovie>[];

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchDebounce?.cancel();
    setState(() {
      _searchResults = <RecommendedMovie>[];
      _searchError = null;
      _isSearching = false;
    });
  }

  Future<void> _performSearch(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchResults = <RecommendedMovie>[];
        _searchError = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final List<RecommendedMovie> results = await AuthApi.searchMedia(trimmed);
      final String needle = trimmed.toLowerCase();
      final List<RecommendedMovie> filtered = results.where((
        RecommendedMovie movie,
      ) {
        final String title = movie.title.toLowerCase();
        return title.contains(needle);
      }).toList();

      if (!mounted) {
        return;
      }
      setState(() {
        _searchResults = filtered;
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchError = error.message;
        _searchResults = <RecommendedMovie>[];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchError = 'Could not search right now.';
        _searchResults = <RecommendedMovie>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  List<Widget> _buildSearchResultsSection() {
    final bool hasQuery = _searchController.text.trim().isNotEmpty;
    if (!hasQuery) {
      return const <Widget>[
        SizedBox(height: 24),
        Center(
          child: Text(
            'Start typing to search movies and shows.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ];
    }

    if (_searchError != null) {
      return <Widget>[];
    }

    if (!_isSearching && _searchResults.isEmpty) {
      return const <Widget>[
        SizedBox(height: 16),
        Text(
          'No matches found.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ];
    }

    return <Widget>[
      const SizedBox(height: 16),
      const Text(
        'Search results',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
      const SizedBox(height: 12),
      ..._searchResults.map(
        (RecommendedMovie movie) => _RecommendationCard(movie: movie),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search movies and shows',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasQuery
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Searching...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Text(
                _searchError!,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _performSearch(_searchController.text),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: _buildSearchResultsSection(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverPage extends StatefulWidget {
  const _DiscoverPage();

  @override
  State<_DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<_DiscoverPage> {
  bool _isLoading = true;
  String? _error;
  List<RecommendedMovie> _results = <RecommendedMovie>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<String> _currentGenres() {
    final dynamic rawGenres = AuthSession.currentUser?['preferredGenres'];
    return rawGenres is List
        ? rawGenres.map((dynamic value) => value.toString()).toList()
        : <String>[];
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final List<String> genres = _currentGenres();
    if (genres.isEmpty) {
      setState(() {
        _results = <RecommendedMovie>[];
        _isLoading = false;
      });
      return;
    }

    try {
      final List<RecommendedMovie> picks =
          await AuthApi.fetchRecommendedMoviesByGenres(genres);

      Set<String> excludedIds = <String>{};
      try {
        final List<WatchlistItem> watchlist = await AuthApi.fetchMyWatchlist();
        excludedIds = watchlist
            .map((WatchlistItem item) => item.imdbID)
            .where((String id) => id.trim().isNotEmpty)
            .toSet();
      } catch (_) {
        // If watchlist fails to load, still show Discover picks.
      }

      final List<RecommendedMovie> filtered = excludedIds.isEmpty
          ? picks
          : picks
                .where(
                  (RecommendedMovie movie) =>
                      !excludedIds.contains(movie.imdbID.trim()),
                )
                .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _results = filtered;
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Could not load Discover right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openGenreSetup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CurationPage(saveOnNext: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> genres = _currentGenres();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discover',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : genres.isEmpty
            ? ListView(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                children: [
                  const Text(
                    'Pick genres to get suggestions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Discover uses the genres you chose when setting up your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _openGenreSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                      ),
                      child: const Text('Set Genres'),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  ..._results.map(
                    (RecommendedMovie movie) => _RecommendationCard(
                      movie: movie,
                      onWatchlistChanged: _load,
                    ),
                  ),
                  if (_results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text(
                          'No suggestions found right now.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.movie, this.onWatchlistChanged});

  final RecommendedMovie movie;
  final VoidCallback? onWatchlistChanged;

  @override
  Widget build(BuildContext context) {
    final String mediaType = movie.type.toLowerCase() == 'series'
        ? 'TV Series'
        : movie.type.toLowerCase() == 'movie'
        ? 'Movie'
        : 'Media';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onTap: movie.imdbID.trim().isEmpty
            ? null
            : () async {
                final bool? changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => MediaDetailPage(
                      imdbID: movie.imdbID,
                      title: movie.title,
                      poster: movie.poster,
                    ),
                  ),
                );

                if (changed == true) {
                  onWatchlistChanged?.call();
                }
              },
        leading: movie.poster != null && movie.poster!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  movie.poster!,
                  width: 44,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.movie),
                ),
              )
            : const Icon(Icons.movie),
        title: Text(
          movie.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        subtitle: Text(
          movie.year.isEmpty ? mediaType : '${movie.year} • $mediaType',
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

class _FeedStatusCard extends StatelessWidget {
  const _FeedStatusCard({required this.item});

  final FriendFeedItem item;

  String _formatStatus(String rawStatus) {
    switch (rawStatus) {
      case 'plan_to_watch':
        return 'plans to watch';
      case 'watching':
        return 'is watching';
      case 'completed':
        return 'finished';
      default:
        return rawStatus;
    }
  }

  Widget _buildRatingRow(double rating) {
    final double normalized = rating > 5 ? rating / 2.0 : rating;
    final double clamped = normalized.clamp(0.0, 5.0);
    final int fullStars = clamped.floor();
    final bool hasHalf = (clamped - fullStars) >= 0.5;
    final int emptyStars = 5 - fullStars - (hasHalf ? 1 : 0);

    final List<Widget> icons = <Widget>[];
    for (int i = 0; i < fullStars; i++) {
      icons.add(const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)));
    }
    if (hasHalf) {
      icons.add(
        const Icon(Icons.star_half, size: 16, color: Color(0xFFF59E0B)),
      );
    }
    for (int i = 0; i < emptyStars; i++) {
      icons.add(
        const Icon(Icons.star_border, size: 16, color: Color(0xFFD1D5DB)),
      );
    }

    return Row(children: icons);
  }

  @override
  Widget build(BuildContext context) {
    final String sentence =
        '${item.username} ${_formatStatus(item.status)} ${item.title}';
    final double? rating = item.userRating;
    final bool canOpen = item.imdbID.trim().isNotEmpty;

    return InkWell(
      onTap: canOpen
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MediaDetailPage(
                    imdbID: item.imdbID,
                    title: item.title,
                    poster: item.poster,
                  ),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sentence,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.dateAdded.toLocal().toString(),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              if (rating != null) ...[
                const SizedBox(height: 6),
                _buildRatingRow(rating),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
