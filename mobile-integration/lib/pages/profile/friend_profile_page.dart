import 'package:flutter/material.dart';

import '../../auth_api.dart';
import '../media/media_detail_page.dart';

class FriendProfilePage extends StatefulWidget {
  const FriendProfilePage({
    super.key,
    required this.friendId,
    required this.initialUsername,
    required this.initialVisibility,
  });

  final String friendId;
  final String initialUsername;
  final String initialVisibility;

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  bool _isLoading = true;
  bool _isRemoving = false;
  String? _error;
  PublicUser? _user;
  List<WatchlistItem> _recentActivity = <WatchlistItem>[];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  bool get _isPrivate {
    final String visibility =
        _user?.profileVisibility ?? widget.initialVisibility;
    return visibility.trim().toLowerCase() == 'private';
  }

  String get _username {
    final String loaded = _user?.username.trim() ?? '';
    if (loaded.isNotEmpty) {
      return loaded;
    }
    return widget.initialUsername.trim().isNotEmpty
        ? widget.initialUsername.trim()
        : 'Friend';
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final PublicUser user = await AuthApi.fetchPublicUser(widget.friendId);
      List<WatchlistItem> activity = <WatchlistItem>[];

      if (user.profileVisibility.trim().toLowerCase() == 'public') {
        final List<WatchlistItem> watchlist = await AuthApi.fetchUserWatchlist(
          widget.friendId,
        );
        watchlist.sort(
          (WatchlistItem a, WatchlistItem b) =>
              b.dateAdded.compareTo(a.dateAdded),
        );
        activity = watchlist.take(12).toList();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _recentActivity = activity;
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
        _error = 'Could not load this profile right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFriend() async {
    setState(() {
      _isRemoving = true;
    });

    try {
      await AuthApi.unfollowUser(widget.friendId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Removed $_username.')));
      Navigator.of(context).pop(true);
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove friend right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });
      }
    }
  }

  String _statusLabel(String status) {
    if (status == 'plan_to_watch') {
      return 'Plan to Watch';
    }
    if (status == 'watching') {
      return 'Watching';
    }
    if (status == 'completed') {
      return 'Completed';
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(title: Text(_username)),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (_user?.createdAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Joined ${_user!.createdAt!.toLocal().toString().split(' ').first}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isRemoving ? null : _removeFriend,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF111827),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              _isRemoving ? 'Removing...' : 'Remove Friend',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isPrivate)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        'Private Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    )
                  else ...[
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_recentActivity.isEmpty)
                      const Text(
                        'No recent activity yet.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      ..._recentActivity.map((WatchlistItem item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ActivityCard(
                            item: item,
                            statusLabel: _statusLabel(item.status),
                          ),
                        );
                      }),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item, required this.statusLabel});

  final WatchlistItem item;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final bool hasPoster = item.poster.trim().startsWith('http');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MediaDetailPage(
              imdbID: item.imdbID,
              title: item.title,
              poster: item.poster,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasPoster
                  ? Image.network(
                      item.poster,
                      width: 52,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _PosterFallback(title: item.title),
                    )
                  : _PosterFallback(title: item.title),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final String firstLetter = title.trim().isNotEmpty
        ? title.trim()[0].toUpperCase()
        : '?';

    return Container(
      width: 52,
      height: 74,
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: Text(
        firstLetter,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }
}
