import 'package:flutter/material.dart';

import '../../app/auth_validation.dart';
import '../../app/constants.dart';
import '../../auth_api.dart';
import '../../widgets/brand_mark.dart';
import '../watchlist/my_watchlist_page.dart';

class CurationPage extends StatefulWidget {
  const CurationPage({super.key, required this.saveOnNext});

  final bool saveOnNext;

  @override
  State<CurationPage> createState() => _CurationPageState();
}

class _CurationPageState extends State<CurationPage> {
  static const List<String> _genres = <String>[
    'Action',
    'Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Fantasy',
    'Horror',
    'Mystery',
    'Romance',
    'Sci-Fi',
    'Thriller',
  ];

  final Set<String> _selectedGenres = <String>{};
  bool _isSubmitting = false;
  String? _serverError;
  bool _isProfileLoading = false;
  bool _isProfileSaving = false;
  String _profileEmail = '';
  String _profileVisibility = 'public';
  List<WatchlistItem> _watchlistItems = <WatchlistItem>[];

  String _formatTitleCount(int count) {
    if (count == 1) {
      return '1 title';
    }
    return '$count titles';
  }

  int _countByStatus(String status) {
    return _watchlistItems
        .where((WatchlistItem item) => item.status == status)
        .length;
  }

  int _countFavorites() {
    return _watchlistItems
        .where((WatchlistItem item) => item.isFavorite == true)
        .length;
  }

  @override
  void initState() {
    super.initState();
    if (!widget.saveOnNext) {
      _loadProfile();
    }
  }

  Future<void> _submitGenres() async {
    if (_selectedGenres.isEmpty) {
      setState(() {
        _serverError = 'Pick at least one genre to continue.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _serverError = null;
    });

    try {
      await AuthApi.saveGenrePreferences(_selectedGenres.toList());

      if (!mounted) {
        return;
      }

      if (widget.saveOnNext) {
        AuthSession.clear();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/feed', (route) => false);
      }
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _serverError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _serverError = 'Could not save preferences. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isProfileLoading = true;
      _serverError = null;
    });

    try {
      final Map<String, dynamic> profile = await AuthApi.fetchProfile();
      final List<WatchlistItem> watchlist = await AuthApi.fetchMyWatchlist();
      if (!mounted) {
        return;
      }
      setState(() {
        _profileEmail = profile['email']?.toString().trim() ?? _profileEmail;
        final String visibility =
            profile['profileVisibility']?.toString().trim().toLowerCase() ??
            _profileVisibility;
        _profileVisibility = visibility == 'private' ? 'private' : 'public';
        _watchlistItems = watchlist;
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _serverError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _serverError = 'Could not load your profile right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
        });
      }
    }
  }

  Future<void> _openEditProfilePage() async {
    final _ProfileEditResult? result = await Navigator.of(context)
        .push<_ProfileEditResult>(
          MaterialPageRoute(
            builder: (_) => _ProfileEditPage(
              email: _profileEmail,
              profileVisibility: _profileVisibility,
            ),
          ),
        );

    if (result == null) {
      return;
    }

    await _saveProfileUpdates(
      email: result.email,
      profileVisibility: result.profileVisibility,
    );
  }

  Future<void> _saveProfileUpdates({
    String? email,
    String? profileVisibility,
  }) async {
    setState(() {
      _isProfileSaving = true;
      _serverError = null;
    });

    try {
      final Map<String, dynamic> payload = await AuthApi.updateProfile(
        email: email,
        profileVisibility: profileVisibility,
      );

      if (!mounted) {
        return;
      }

      final dynamic userPayload = payload['user'];
      if (userPayload is Map) {
        final Map<String, dynamic> profile = <String, dynamic>{
          for (final MapEntry<dynamic, dynamic> entry in userPayload.entries)
            entry.key.toString(): entry.value,
        };
        setState(() {
          _profileEmail = profile['email']?.toString().trim() ?? _profileEmail;
          _profileVisibility =
              profile['profileVisibility']?.toString().trim().toLowerCase() ==
                  'private'
              ? 'private'
              : 'public';
        });
      }

      _showSnackBar('Profile updated successfully.');
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _serverError = error.message;
      });
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _serverError = 'Could not update your profile right now.';
      });
      _showSnackBar('Could not update your profile right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isProfileSaving = false;
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

  Future<void> _openMyWatchlist([
    MyWatchlistView view = MyWatchlistView.all,
  ]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MyWatchlistPage(view: view)),
    );

    if (changed == true) {
      await _loadProfile();
    }
  }

  Widget _buildProfileTopNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8FA),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/feed', (route) => false);
              },
              child: const BrandMark(
                assetPath: watchItLogoAssetPath,
                width: 56,
              ),
            ),
            const SizedBox(width: 14),
            TextButton(
              onPressed: _openMyWatchlist,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              child: const Text('My Watchlist'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.saveOnNext) {
      return _buildProfilePage();
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose what you want to\nwatch',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pick your favorite genres so WatchIt can personalize your feed.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 22),
                _CurationTile(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFBAD8D3),
                      Color(0xFF88C6BC),
                      Color(0xFFB6D9D3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  overlay: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _genres.map((String genre) {
                        final bool isSelected = _selectedGenres.contains(genre);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(genre),
                          selectedColor: const Color(0xFF2F86E2),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedGenres.add(genre);
                              } else {
                                _selectedGenres.remove(genre);
                              }
                              _serverError = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  '${_selectedGenres.length} selected',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_serverError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _serverError!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Center(
                  child: TextButton(
                    onPressed: _isSubmitting ? null : _submitGenres,
                    child: Text(
                      _isSubmitting ? 'Saving...' : 'Next',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    final int wantToWatchCount = _countByStatus('plan_to_watch');
    final int alreadyWatchedCount = _countByStatus('completed');
    final int favoritesCount = _countFavorites();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            children: [
              _buildProfileTopNav(),
              const SizedBox(height: 18),
              const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1D21),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_serverError != null) ...[
                      Text(
                        _serverError!,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      child: FilledButton(
                        onPressed: _isProfileSaving
                            ? null
                            : _openEditProfilePage,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF101114),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isProfileSaving ? 'Saving...' : 'Edit Profile',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'My Lists',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _ProfileListCard(
                title: 'Want to Watch',
                subtitle: _formatTitleCount(wantToWatchCount),
                accentGradient: const LinearGradient(
                  colors: [Color(0xFFFBE2F0), Color(0xFFF5BDD9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                artIcon: Icons.circle,
                artColor: const Color(0xFFE238A5),
                onTap: () => _openMyWatchlist(MyWatchlistView.watchlist),
              ),
              const SizedBox(height: 16),
              _ProfileListCard(
                title: 'Already Watched',
                subtitle: _formatTitleCount(alreadyWatchedCount),
                accentGradient: const LinearGradient(
                  colors: [Color(0xFFDCE7F1), Color(0xFFB0D0BA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                artIcon: Icons.terrain,
                artColor: const Color(0xFF355E72),
                onTap: () => _openMyWatchlist(MyWatchlistView.watched),
              ),
              const SizedBox(height: 16),
              _ProfileListCard(
                title: 'Favorites',
                subtitle: _formatTitleCount(favoritesCount),
                accentGradient: const LinearGradient(
                  colors: [Color(0xFFE0DEEE), Color(0xFFADC2F2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                artIcon: Icons.change_history,
                artColor: const Color(0xFF6A7FC9),
                onTap: () => _openMyWatchlist(MyWatchlistView.favorites),
              ),
              if (_isProfileLoading) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileEditResult {
  const _ProfileEditResult({
    required this.email,
    required this.profileVisibility,
  });

  final String email;
  final String profileVisibility;
}

class _ProfileEditPage extends StatefulWidget {
  const _ProfileEditPage({
    required this.email,
    required this.profileVisibility,
  });

  final String email;
  final String profileVisibility;

  @override
  State<_ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<_ProfileEditPage> {
  late final TextEditingController _emailController;
  late String _selectedVisibility;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _selectedVisibility = widget.profileVisibility == 'private'
        ? 'private'
        : 'public';
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = 'Email is required.';
      });
      return;
    }
    if (!AuthValidation.isEmailFormatValid(email)) {
      setState(() {
        _error = 'Please enter a valid email address.';
      });
      return;
    }

    Navigator.of(context).pop(
      _ProfileEditResult(email: email, profileVisibility: _selectedVisibility),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_error != null) {
                      setState(() {
                        _error = null;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedVisibility,
                  decoration: const InputDecoration(
                    labelText: 'Profile Visibility',
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'public',
                      child: Text('Public'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'private',
                      child: Text('Private'),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedVisibility = value;
                    });
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF101114),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileListCard extends StatelessWidget {
  const _ProfileListCard({
    required this.title,
    required this.subtitle,
    required this.accentGradient,
    required this.artIcon,
    required this.artColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Gradient accentGradient;
  final IconData artIcon;
  final Color artColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          height: 318,
          decoration: BoxDecoration(
            color: const Color(0xFFE9E9EC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 118),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF696969),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 104,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: accentGradient),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(artIcon, size: 66, color: artColor),
                        const SizedBox(width: 14),
                        Icon(
                          artIcon,
                          size: 46,
                          color: artColor.withAlpha((0.75 * 255).round()),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          artIcon,
                          size: 56,
                          color: artColor.withAlpha((0.9 * 255).round()),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurationTile extends StatelessWidget {
  const _CurationTile({required this.gradient, this.overlay});

  final Gradient gradient;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 172,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: gradient,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: overlay ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
