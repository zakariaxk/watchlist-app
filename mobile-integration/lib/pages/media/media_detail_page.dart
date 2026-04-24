import 'package:flutter/material.dart';

import '../../auth_api.dart';

class MediaDetailPage extends StatefulWidget {
  const MediaDetailPage({
    super.key,
    required this.imdbID,
    required this.title,
    required this.poster,
  });

  final String imdbID;
  final String title;
  final String? poster;

  @override
  State<MediaDetailPage> createState() => _MediaDetailPageState();
}

class _MediaDetailPageState extends State<MediaDetailPage> {
  bool _isLoading = true;
  String? _error;
  MediaDetail? _detail;
  bool _isAdding = false;
  bool _added = false;
  bool _isRemoving = false;
  WatchlistItem? _watchlistItem;
  bool _watchlistChanged = false;
  bool _isTogglingFavorite = false;
  bool _isUpdatingRating = false;

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

  double _currentStarRating() {
    final double raw = _watchlistItem?.userRating ?? 0.0;
    if (raw <= 0) {
      return 0.0;
    }
    final double normalized = raw > 5 ? raw / 2.0 : raw;
    return normalized.clamp(0.0, 5.0);
  }

  Future<void> _setRating(double stars) async {
    if (_isUpdatingRating) {
      return;
    }

    final WatchlistItem? current = _watchlistItem;
    if (current == null || current.id.trim().isEmpty) {
      return;
    }

    final double nextRating = stars.clamp(0.5, 5.0);

    setState(() {
      _isUpdatingRating = true;
      _watchlistItem = current.copyWith(userRating: nextRating);
      _watchlistChanged = true;
    });

    try {
      final WatchlistItem updated = await AuthApi.updateWatchlistItem(
        id: current.id,
        userRating: nextRating,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _watchlistItem = updated.copyWith(userRating: nextRating);
      });
      _showSnackBar('Rating saved.');
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _watchlistItem = current;
      });
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _watchlistItem = current;
      });
      _showSnackBar('Could not update rating right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingRating = false;
        });
      }
    }
  }

  Widget _buildRatingSection() {
    final WatchlistItem? current = _watchlistItem;
    if (current == null) {
      return const SizedBox.shrink();
    }

    if (current.status != 'completed') {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text(
          'Mark as watched to add a rating.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    final double rating = _currentStarRating();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Your rating',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List<Widget>.generate(5, (int index) {
            final double starIndex = index + 1.0;
            final bool filled = rating >= starIndex;
            final bool halfFilled = !filled && rating >= (starIndex - 0.5);
            final IconData icon = filled
                ? Icons.star
                : (halfFilled ? Icons.star_half : Icons.star_border);

            return Builder(
              builder: (BuildContext context) => GestureDetector(
                onTapDown: _isUpdatingRating
                    ? null
                    : (TapDownDetails details) {
                        final RenderBox box =
                            context.findRenderObject() as RenderBox;
                        final double localDx = details.localPosition.dx;
                        final double halfPoint = box.size.width / 2;
                        final double next = localDx < halfPoint
                            ? starIndex - 0.5
                            : starIndex;
                        _setRating(next);
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(icon, color: const Color(0xFFF59E0B)),
                ),
              ),
            );
          }),
        ),
      ],
    );
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
                    _buildRatingSection(),
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
