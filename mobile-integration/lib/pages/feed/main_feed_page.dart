import 'package:flutter/material.dart';

import '../../auth_api.dart';
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
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                children: [
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
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return Center(
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
                    );
                  }

                  if (index == 1) {
                    return const Text(
                      'Friends Feed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    );
                  }

                  final FriendFeedItem item = _feedItems[index - 2];
                  return _FeedStatusCard(item: item);
                },
                separatorBuilder: (_, index) => index == 0
                    ? const SizedBox(height: 20)
                    : const SizedBox(height: 12),
                itemCount: _feedItems.length + 2,
              ),
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
                    builder: (_) => _MediaDetailPage(
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

class _MediaDetailPage extends StatefulWidget {
  const _MediaDetailPage({
    required this.imdbID,
    required this.title,
    required this.poster,
  });

  final String imdbID;
  final String title;
  final String? poster;

  @override
  State<_MediaDetailPage> createState() => _MediaDetailPageState();
}

class _MediaDetailPageState extends State<_MediaDetailPage> {
  bool _isLoading = true;
  String? _error;
  MediaDetail? _detail;
  bool _isAdding = false;
  bool _added = false;
  bool _isRemoving = false;
  WatchlistItem? _watchlistItem;
  bool _watchlistChanged = false;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final MediaDetail detail = await AuthApi.fetchMediaDetail(widget.imdbID);

      WatchlistItem? existing;
      try {
        final List<WatchlistItem> watchlist = await AuthApi.fetchMyWatchlist();
        existing = watchlist.cast<WatchlistItem?>().firstWhere(
          (WatchlistItem? item) => item?.imdbID == widget.imdbID,
          orElse: () => null,
        );
      } catch (_) {
        // Ignore watchlist lookup failures; detail screen can still render.
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _watchlistItem = existing;
        _added = existing != null;
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
        _error = 'Could not load details right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addToWatchlist() async {
    if (_isAdding || _added) {
      return;
    }

    setState(() {
      _isAdding = true;
      _error = null;
    });

    try {
      final WatchlistItem item = await AuthApi.addToWatchlist(
        imdbID: widget.imdbID,
        title: _detail?.title ?? widget.title,
        poster: _detail?.poster.isNotEmpty == true
            ? _detail!.poster
            : widget.poster,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _added = true;
        _watchlistItem = item;
        _watchlistChanged = true;
      });
      _showSnackBar('Added to watchlist!');
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      final String msg = error.message;
      if (msg.toLowerCase().contains('already in watchlist')) {
        WatchlistItem? existing;
        try {
          final List<WatchlistItem> watchlist =
              await AuthApi.fetchMyWatchlist();
          existing = watchlist.cast<WatchlistItem?>().firstWhere(
            (WatchlistItem? item) => item?.imdbID == widget.imdbID,
            orElse: () => null,
          );
        } catch (_) {
          // Ignore.
        }

        setState(() {
          _added = true;
          _watchlistItem = existing;
          _watchlistChanged = true;
        });
      }
      _showSnackBar(msg);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Could not update watchlist right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  Future<void> _removeFromWatchlist() async {
    if (_isRemoving || !_added) {
      return;
    }

    setState(() {
      _isRemoving = true;
      _error = null;
    });

    try {
      WatchlistItem? current = _watchlistItem;
      if (current == null || current.id.trim().isEmpty) {
        try {
          final List<WatchlistItem> watchlist =
              await AuthApi.fetchMyWatchlist();
          current = watchlist.cast<WatchlistItem?>().firstWhere(
            (WatchlistItem? item) => item?.imdbID == widget.imdbID,
            orElse: () => null,
          );
        } catch (_) {
          // Ignore.
        }
      }

      if (current == null || current.id.trim().isEmpty) {
        throw AuthApiException('Could not find this item in your watchlist.');
      }

      await AuthApi.deleteWatchlistItem(current.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _added = false;
        _watchlistItem = null;
        _watchlistChanged = true;
      });
      _showSnackBar('Removed from watchlist.');
    } on AuthApiException catch (error) {
      _showSnackBar(error.message);
    } catch (_) {
      _showSnackBar('Could not update watchlist right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) {
      return;
    }

    final WatchlistItem? originalItem = _watchlistItem;

    setState(() {
      _isTogglingFavorite = true;
      _error = null;
    });

    try {
      final WatchlistItem? current = originalItem;
      final bool previousFavorite = current?.isFavorite == true;
      if (current != null && current.id.trim().isNotEmpty) {
        final bool nextFavorite = !previousFavorite;

        setState(() {
          _watchlistItem = current.copyWith(isFavorite: nextFavorite);
          _added = true;
          _watchlistChanged = true;
        });

        await AuthApi.setLocalFavorite(
          imdbID: current.imdbID,
          isFavorite: nextFavorite,
        );

        final WatchlistItem updated = await AuthApi.updateWatchlistItem(
          id: current.id,
          isFavorite: nextFavorite,
        );

        final WatchlistItem merged = updated.copyWith(isFavorite: nextFavorite);

        if (!mounted) {
          return;
        }

        setState(() {
          _watchlistItem = merged;
          _added = true;
          _watchlistChanged = true;
        });

        _showSnackBar(
          merged.isFavorite == true
              ? 'Added to favorites.'
              : 'Removed from favorites.',
        );
      } else {
        final WatchlistItem created = await AuthApi.addToWatchlist(
          imdbID: widget.imdbID,
          title: _detail?.title ?? widget.title,
          poster: _detail?.poster.isNotEmpty == true
              ? _detail!.poster
              : widget.poster,
          isFavorite: true,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _watchlistItem = created;
          _added = true;
          _watchlistChanged = true;
        });
        _showSnackBar('Added to favorites.');
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        setState(() {
          _watchlistItem = originalItem;
        });
      }

      if (originalItem != null) {
        await AuthApi.setLocalFavorite(
          imdbID: originalItem.imdbID,
          isFavorite: originalItem.isFavorite == true,
        );
      }
      _showSnackBar(error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _watchlistItem = originalItem;
        });
      }

      if (originalItem != null) {
        await AuthApi.setLocalFavorite(
          imdbID: originalItem.imdbID,
          isFavorite: originalItem.isFavorite == true,
        );
      }
      _showSnackBar('Could not update favorites right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = _detail?.title ?? widget.title;
    final String poster = _detail?.poster.isNotEmpty == true
        ? _detail!.poster
        : (widget.poster ?? '');
    final String year = _detail?.year ?? '';
    final String mediaType = _detail?.type.toLowerCase() == 'series'
        ? 'TV Series'
        : _detail?.type.toLowerCase() == 'movie'
        ? 'Movie'
        : 'Media';
    final List<String> genres = _detail?.genres ?? <String>[];
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, bool? result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_watchlistChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title.isEmpty ? 'Details' : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              onPressed: _isTogglingFavorite ? null : _toggleFavorite,
              icon: Icon(
                _watchlistItem?.isFavorite == true
                    ? Icons.star
                    : Icons.star_border,
              ),
            ),
          ],
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
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    if (poster.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            poster,
                            width: 180,
                            height: 260,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.movie,
                              size: 90,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(
                          Icons.movie,
                          size: 90,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        year,
                        mediaType,
                      ].where((String v) => v.trim().isNotEmpty).join(' • '),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if (genres.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: genres
                            .take(6)
                            .map(
                              (String genre) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Text(
                                  genre,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _added
                            ? null
                            : (_isAdding ? null : _addToWatchlist),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF101114),
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _added
                              ? 'In Watchlist'
                              : (_isAdding ? 'Adding...' : 'Add to Watchlist'),
                        ),
                      ),
                    ),
                    if (_added) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isRemoving ? null : _removeFromWatchlist,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            foregroundColor: Colors.black,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                          ),
                          child: Text(
                            _isRemoving
                                ? 'Removing...'
                                : 'Remove from Watchlist',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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

  @override
  Widget build(BuildContext context) {
    final String sentence =
        '${item.username} ${_formatStatus(item.status)} ${item.title}';

    return Container(
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
          ],
        ),
      ),
    );
  }
}
