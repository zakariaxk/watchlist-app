import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/auth_validation.dart';
import '../../app/constants.dart';
import '../../auth_api.dart';
import '../watchlist/my_watchlist_page.dart';
import '../../widgets/brand_mark.dart';

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
  bool _isSearchingUsers = false;
  String _profileEmail = '';
  String _profileVisibility = 'public';
  String _userSearchQuery = '';
  String? _friendActionUserId;
  List<FriendUser> _friends = <FriendUser>[];
  List<PublicUser> _userSearchResults = <PublicUser>[];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    if (!widget.saveOnNext) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
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
      final List<FriendUser> friends = await AuthApi.fetchFriends();
      if (!mounted) {
        return;
      }
      setState(() {
        _profileEmail = profile['email']?.toString().trim() ?? _profileEmail;
        final String visibility =
            profile['profileVisibility']?.toString().trim().toLowerCase() ??
            _profileVisibility;
        _profileVisibility = visibility == 'private' ? 'private' : 'public';
        _friends = friends;
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

  Future<void> _searchUsers(String query) async {
    final String trimmed = query.trim();
    _searchDebounce?.cancel();

    setState(() {
      _userSearchQuery = query;
      if (trimmed.length < 2) {
        _isSearchingUsers = false;
        _userSearchResults = <PublicUser>[];
      }
    });

    if (trimmed.length < 2) {
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSearchingUsers = true;
      });

      try {
        final String? currentUserId =
            AuthSession.currentUser?['_id']?.toString() ??
            AuthSession.currentUser?['id']?.toString();
        final Set<String> friendIds = _friends
            .map((FriendUser friend) => friend.id)
            .toSet();
        final List<PublicUser> users = await AuthApi.searchUsers(trimmed);

        if (!mounted || _userSearchQuery.trim() != trimmed) {
          return;
        }

        setState(() {
          _userSearchResults = users.where((PublicUser user) {
            return user.id.isNotEmpty &&
                user.id != currentUserId &&
                !friendIds.contains(user.id);
          }).toList();
        });
      } on AuthApiException catch (error) {
        if (!mounted || _userSearchQuery.trim() != trimmed) {
          return;
        }

        setState(() {
          _userSearchResults = <PublicUser>[];
          _serverError = error.message;
        });
      } catch (_) {
        if (!mounted || _userSearchQuery.trim() != trimmed) {
          return;
        }

        setState(() {
          _userSearchResults = <PublicUser>[];
          _serverError = 'Could not search users right now.';
        });
      } finally {
        if (mounted && _userSearchQuery.trim() == trimmed) {
          setState(() {
            _isSearchingUsers = false;
          });
        }
      }
    });
  }

  Future<void> _followUser(PublicUser user) async {
    setState(() {
      _friendActionUserId = user.id;
      _serverError = null;
    });

    try {
      await AuthApi.followUser(user.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _friends = <FriendUser>[
          FriendUser(
            id: user.id,
            username: user.username,
            profileVisibility: user.profileVisibility,
          ),
          ..._friends,
        ];
        _userSearchResults = _userSearchResults
            .where((PublicUser candidate) => candidate.id != user.id)
            .toList();
      });
      _showSnackBar('Added ${user.username}.');
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
        _serverError = 'Could not add friend right now.';
      });
      _showSnackBar('Could not add friend right now.');
    } finally {
      if (mounted) {
        setState(() {
          _friendActionUserId = null;
        });
      }
    }
  }

  Future<void> _unfollowUser(FriendUser user) async {
    setState(() {
      _friendActionUserId = user.id;
      _serverError = null;
    });

    try {
      await AuthApi.unfollowUser(user.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _friends = _friends
            .where((FriendUser friend) => friend.id != user.id)
            .toList();
      });
      _showSnackBar('Removed ${user.username}.');
      if (_userSearchQuery.trim().length >= 2) {
        await _searchUsers(_userSearchQuery);
      }
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
        _serverError = 'Could not remove friend right now.';
      });
      _showSnackBar('Could not remove friend right now.');
    } finally {
      if (mounted) {
        setState(() {
          _friendActionUserId = null;
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
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MyWatchlistPage(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF101114),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'My Watchlist',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                'Find People',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: _searchUsers,
                decoration: InputDecoration(
                  hintText: 'Search users by username...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                ),
              ),
              if (_userSearchQuery.trim().isNotEmpty &&
                  _userSearchQuery.trim().length < 2) ...[
                const SizedBox(height: 10),
                const Text(
                  'Type at least 2 characters to search.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (_isSearchingUsers) ...[
                const SizedBox(height: 14),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_userSearchResults.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._userSearchResults.map((PublicUser user) {
                  final bool isSubmitting = _friendActionUserId == user.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UserActionCard(
                      username: user.username,
                      profileVisibility: user.profileVisibility,
                      actionLabel: isSubmitting ? 'Adding...' : 'Add',
                      onAction: isSubmitting ? null : () => _followUser(user),
                    ),
                  );
                }),
              ] else if (!_isSearchingUsers &&
                  _userSearchQuery.trim().length >= 2) ...[
                const SizedBox(height: 10),
                const Text(
                  'No users found.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Friends',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_friends.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_friends.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isProfileLoading) ...[
                const Center(child: CircularProgressIndicator()),
              ] else if (_friends.isEmpty) ...[
                const Text(
                  'You have not added any friends yet.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                ..._friends.map((FriendUser user) {
                  final bool isSubmitting = _friendActionUserId == user.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UserActionCard(
                      username: user.username,
                      profileVisibility: user.profileVisibility,
                      actionLabel: isSubmitting ? 'Removing...' : 'Remove',
                      onAction: isSubmitting ? null : () => _unfollowUser(user),
                    ),
                  );
                }),
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

class _UserActionCard extends StatelessWidget {
  const _UserActionCard({
    required this.username,
    required this.profileVisibility,
    required this.actionLabel,
    this.onAction,
  });

  final String username;
  final String profileVisibility;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final bool isPrivate = profileVisibility.trim().toLowerCase() == 'private';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPrivate ? 'Private profile' : 'Public profile',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
