import 'package:flutter/material.dart';

import '../../auth_api.dart';
import '../media/media_detail_page.dart';

enum MyWatchlistView { all, watchlist, watched, favorites }

class MyWatchlistPage extends StatefulWidget {
  const MyWatchlistPage({super.key, this.view = MyWatchlistView.all});

  final MyWatchlistView view;

  @override
  State<MyWatchlistPage> createState() => _MyWatchlistPageState();
}

class _MyWatchlistPageState extends State<MyWatchlistPage> {
  bool _isLoading = true;
  String? _error;
  List<WatchlistItem> _items = <WatchlistItem>[];
  bool _changed = false;

  final Set<String> _favoriteInFlight = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<WatchlistItem> items = await AuthApi.fetchMyWatchlist();
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
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
        _error = 'Could not load your watchlist right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markWatched(WatchlistItem item) async {
    try {
      final WatchlistItem updated = await AuthApi.updateWatchlistItem(
        id: item.id,
        status: 'completed',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _changed = true;
        _items = _items
            .map((WatchlistItem i) => i.id == updated.id ? updated : i)
            .toList();
      });
      _showSnackBar('Moved to Watched.');
    } on AuthApiException catch (error) {
      _showSnackBar(error.message);
    } catch (_) {
      _showSnackBar('Could not update watchlist right now.');
    }
  }

  Future<void> _remove(WatchlistItem item) async {
    try {
      await AuthApi.deleteWatchlistItem(item.id);
      await AuthApi.setLocalFavorite(imdbID: item.imdbID, isFavorite: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _changed = true;
        _items = _items.where((WatchlistItem i) => i.id != item.id).toList();
      });
      _showSnackBar('Removed from your lists.');
    } on AuthApiException catch (error) {
      _showSnackBar(error.message);
    } catch (_) {
      _showSnackBar('Could not update watchlist right now.');
    }
  }

  Future<void> _toggleFavorite(WatchlistItem item) async {
    final String id = item.id.trim();
    if (id.isEmpty || _favoriteInFlight.contains(id)) {
      return;
    }

    final bool previousFavorite = item.isFavorite == true;
    final bool nextFavorite = !previousFavorite;

    setState(() {
      _favoriteInFlight.add(id);
      _changed = true;
      _items = _items
          .map(
            (WatchlistItem i) =>
                i.id == item.id ? i.copyWith(isFavorite: nextFavorite) : i,
          )
          .toList();
    });

    await AuthApi.setLocalFavorite(
      imdbID: item.imdbID,
      isFavorite: nextFavorite,
    );

    try {
      final WatchlistItem updated = await AuthApi.updateWatchlistItem(
        id: item.id,
        isFavorite: nextFavorite,
      );

      final WatchlistItem merged = updated.copyWith(isFavorite: nextFavorite);

      if (!mounted) {
        return;
      }

      setState(() {
        _favoriteInFlight.remove(id);
        _items = _items
            .map((WatchlistItem i) => i.id == merged.id ? merged : i)
            .toList();
      });

      _showSnackBar(
        merged.isFavorite == true
            ? 'Added to favorites.'
            : 'Removed from favorites.',
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _favoriteInFlight.remove(id);
        _items = _items
            .map(
              (WatchlistItem i) => i.id == item.id
                  ? i.copyWith(isFavorite: previousFavorite)
                  : i,
            )
            .toList();
      });

      await AuthApi.setLocalFavorite(
        imdbID: item.imdbID,
        isFavorite: previousFavorite,
      );
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _favoriteInFlight.remove(id);
        _items = _items
            .map(
              (WatchlistItem i) => i.id == item.id
                  ? i.copyWith(isFavorite: previousFavorite)
                  : i,
            )
            .toList();
      });

      await AuthApi.setLocalFavorite(
        imdbID: item.imdbID,
        isFavorite: previousFavorite,
      );
      _showSnackBar('Could not update favorites right now.');
    }
  }

  Future<void> _openDetails(WatchlistItem item) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MediaDetailPage(
          imdbID: item.imdbID,
          title: item.title,
          poster: item.poster,
        ),
      ),
    );

    if (changed == true) {
      _changed = true;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<WatchlistItem> watchlist = _items
        .where((WatchlistItem item) => item.status != 'completed')
        .toList();
    final List<WatchlistItem> watched = _items
        .where((WatchlistItem item) => item.status == 'completed')
        .toList();

    final List<WatchlistItem> favorites = _items
        .where((WatchlistItem item) => item.isFavorite == true)
        .toList();

    final bool showFavorites = widget.view == MyWatchlistView.favorites;
    final bool showWatchlist = showFavorites
        ? false
        : widget.view != MyWatchlistView.watched;
    final bool showWatched = showFavorites
        ? false
        : widget.view != MyWatchlistView.watchlist;

    final String title = widget.view == MyWatchlistView.watchlist
        ? 'Want to Watch'
        : widget.view == MyWatchlistView.watched
        ? 'Already Watched'
        : widget.view == MyWatchlistView.favorites
        ? 'Favorites'
        : 'My Watchlist';

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, bool? result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
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
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    if (showFavorites) ...[
                      if (favorites.isEmpty)
                        const Text(
                          'No favorites yet.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                          ),
                        )
                      else
                        ...favorites.map(
                          (WatchlistItem item) => _WatchlistItemCard(
                            item: item,
                            onTap: () => _openDetails(item),
                            onToggleFavorite: () => _toggleFavorite(item),
                            primaryLabel: item.status == 'completed'
                                ? null
                                : 'Mark Watched',
                            onPrimary: item.status == 'completed'
                                ? null
                                : () => _markWatched(item),
                            secondaryLabel: 'Remove',
                            onSecondary: () => _remove(item),
                          ),
                        ),
                    ],
                    if (showWatchlist) ...[
                      const Text(
                        'Watchlist',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (watchlist.isEmpty)
                        const Text(
                          'No titles in your watchlist.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                          ),
                        )
                      else
                        ...watchlist.map(
                          (WatchlistItem item) => _WatchlistItemCard(
                            item: item,
                            onTap: () => _openDetails(item),
                            onToggleFavorite: () => _toggleFavorite(item),
                            primaryLabel: 'Mark Watched',
                            onPrimary: () => _markWatched(item),
                            secondaryLabel: 'Remove',
                            onSecondary: () => _remove(item),
                          ),
                        ),
                    ],
                    if (showWatchlist && showWatched)
                      const SizedBox(height: 24),
                    if (showWatched) ...[
                      const Text(
                        'Watched',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (watched.isEmpty)
                        const Text(
                          'No watched titles yet.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                          ),
                        )
                      else
                        ...watched.map(
                          (WatchlistItem item) => _WatchlistItemCard(
                            item: item,
                            onTap: () => _openDetails(item),
                            onToggleFavorite: () => _toggleFavorite(item),
                            primaryLabel: null,
                            onPrimary: null,
                            secondaryLabel: 'Remove',
                            onSecondary: () => _remove(item),
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

class _WatchlistItemCard extends StatelessWidget {
  const _WatchlistItemCard({
    required this.item,
    required this.onTap,
    required this.onToggleFavorite,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final WatchlistItem item;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final bool hasPoster = item.poster.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: hasPoster
                    ? Image.network(
                        item.poster,
                        width: 58,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.movie),
                      )
                    : const SizedBox(
                        width: 58,
                        height: 84,
                        child: Icon(Icons.movie),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title.isEmpty ? item.imdbID : item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onToggleFavorite,
                          icon: Icon(
                            item.isFavorite == true
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (primaryLabel != null && onPrimary != null) ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: onPrimary,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF101114),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(primaryLabel!),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onSecondary,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F4F6),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                            ),
                            child: Text(secondaryLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
