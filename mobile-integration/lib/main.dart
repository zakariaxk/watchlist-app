import 'package:flutter/material.dart';

import 'auth_api.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static const String _logoAssetPath = 'assets/images/watch_it_logo.png';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Watch It',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEF5350),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const _HomePage(logoAssetPath: _logoAssetPath),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.logoAssetPath});

  final String logoAssetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double heroGap = constraints.maxHeight < 700 ? 40 : 64;
            final double logoWidth = constraints.maxWidth < 700 ? 320 : 460;
            final double heroHeight = constraints.maxWidth < 700 ? 220 : 280;

            return Column(
              children: [
                _TopNavigation(logoAssetPath: logoAssetPath),
                Expanded(
                  child: Align(
                    alignment: const Alignment(0, -0.35),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => _SignUpPage(
                                      logoAssetPath: logoAssetPath,
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              child: const Text('New? Sign-Up Here!'),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: logoWidth,
                              height: heroHeight,
                              child: _HeroArtwork(assetPath: logoAssetPath),
                            ),
                            SizedBox(height: heroGap),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => _LogInPage(
                                      logoAssetPath: logoAssetPath,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF3F4F6),
                                foregroundColor: Colors.black,
                                side: const BorderSide(
                                  color: Color(0xFFB8BCC4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 36,
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Log In'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SignUpPage extends StatelessWidget {
  const _SignUpPage({required this.logoAssetPath});

  final String logoAssetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              _TopNavigation(logoAssetPath: logoAssetPath),
              const _BackToHomeButton(),
              const SizedBox(height: 40),
              const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC8C8C8)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: _SignUpForm(
                      onSuccess: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                const _CurationPage(saveOnNext: true),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogInPage extends StatelessWidget {
  const _LogInPage({required this.logoAssetPath});

  final String logoAssetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              _TopNavigation(logoAssetPath: logoAssetPath),
              const _BackToHomeButton(),
              const SizedBox(height: 40),
              const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC8C8C8)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: const _LogInForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogInForm extends StatefulWidget {
  const _LogInForm();

  @override
  State<_LogInForm> createState() => _LogInFormState();
}

class _LogInFormState extends State<_LogInForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _usernameError;
  String? _passwordError;
  String? _serverError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() {
      _usernameError = username.isEmpty ? 'Username is required' : null;
      _passwordError = password.isEmpty ? 'Password is required' : null;
      _serverError = null;
    });

    if (_usernameError != null || _passwordError != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final AuthResult result = await AuthApi.login(
        username: username,
        password: password,
      );

      AuthSession.setSession(user: result.user, token: result.token);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const _MainFeedPage()),
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _serverError = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _serverError = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(text: 'Username'),
        const SizedBox(height: 10),
        _SignUpInput(
          hint: 'Your username',
          controller: _usernameController,
          errorText: _usernameError,
          onChanged: (value) {
            if (value.trim().isNotEmpty && _usernameError != null) {
              setState(() {
                _usernameError = null;
              });
            }
          },
        ),
        const SizedBox(height: 18),
        const _FieldLabel(text: 'Password'),
        const SizedBox(height: 10),
        _SignUpInput(
          hint: 'Password',
          controller: _passwordController,
          errorText: _passwordError,
          obscureText: true,
          onChanged: (value) {
            if (value.trim().isNotEmpty && _passwordError != null) {
              setState(() {
                _passwordError = null;
              });
            }
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B2B2D),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(_isSubmitting ? 'Logging in...' : 'Continue'),
          ),
        ),
        if (_serverError != null) ...[
          const SizedBox(height: 12),
          Text(
            _serverError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB91C1C),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _serverError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    final List<String> missingFields = <String>[];

    String? nextEmailError;
    String? nextUsernameError;
    String? nextPasswordError;

    if (email.isEmpty) {
      nextEmailError = 'Email is required';
      missingFields.add('Email');
    }
    if (username.isEmpty) {
      nextUsernameError = 'Username is required';
      missingFields.add('Username');
    }
    if (password.isEmpty) {
      nextPasswordError = 'Password is required';
      missingFields.add('Password');
    }

    setState(() {
      _emailError = nextEmailError;
      _usernameError = nextUsernameError;
      _passwordError = nextPasswordError;
      _serverError = null;
    });

    if (missingFields.isNotEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final AuthResult result = await AuthApi.register(
        username: username,
        email: email,
        password: password,
      );

      AuthSession.setSession(user: result.user, token: result.token);

      if (!mounted) {
        return;
      }

      widget.onSuccess();
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _serverError = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _serverError = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(text: 'Email'),
        const SizedBox(height: 10),
        _SignUpInput(
          hint: 'xxx@email.com',
          controller: _emailController,
          errorText: _emailError,
          onChanged: (value) {
            if (value.trim().isNotEmpty && _emailError != null) {
              setState(() {
                _emailError = null;
              });
            }
          },
        ),
        const SizedBox(height: 18),
        const _FieldLabel(text: 'Username'),
        const SizedBox(height: 10),
        _SignUpInput(
          hint: 'Username',
          controller: _usernameController,
          errorText: _usernameError,
          onChanged: (value) {
            if (value.trim().isNotEmpty && _usernameError != null) {
              setState(() {
                _usernameError = null;
              });
            }
          },
        ),
        const SizedBox(height: 18),
        const _FieldLabel(text: 'Password'),
        const SizedBox(height: 10),
        _SignUpInput(
          hint: 'Password',
          controller: _passwordController,
          errorText: _passwordError,
          obscureText: true,
          onChanged: (value) {
            if (value.trim().isNotEmpty && _passwordError != null) {
              setState(() {
                _passwordError = null;
              });
            }
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B2B2D),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(_isSubmitting ? 'Creating account...' : 'Submit'),
          ),
        ),
        if (_serverError != null) ...[
          const SizedBox(height: 12),
          Text(
            _serverError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB91C1C),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _CurationPage extends StatefulWidget {
  const _CurationPage({required this.saveOnNext});

  final bool saveOnNext;

  @override
  State<_CurationPage> createState() => _CurationPageState();
}

class _CurationPageState extends State<_CurationPage> {
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
  String _introduction =
      'A little paragraph introduction that gives a sense of what you do, '
      'who you are, where you\'re from, and why you created this website.';

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

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const _MainFeedPage()),
        (route) => false,
      );
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
        final String intro = profile['introduction']?.toString().trim() ?? '';
        if (intro.isNotEmpty) {
          _introduction = intro;
        }

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

  Future<void> _openEditIntroductionDialog() async {
    final TextEditingController introController = TextEditingController(
      text: _introduction,
    );

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Introduction'),
          content: SizedBox(
            width: 360,
            child: TextField(
              controller: introController,
              minLines: 4,
              maxLines: 7,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Tell people about yourself...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final String nextIntro = introController.text.trim();
    setState(() {
      _isProfileSaving = true;
      _serverError = null;
    });

    try {
      final Map<String, dynamic> payload = await AuthApi.updateProfile(
        introduction: nextIntro,
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
          _introduction =
              profile['introduction']?.toString().trim() ?? nextIntro;
        });
      } else {
        setState(() {
          _introduction = nextIntro;
        });
      }

      if (AuthSession.currentUser != null) {
        AuthSession.currentUser!['introduction'] = _introduction;
      }

      _showSnackBar('Introduction updated.');
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
        _serverError = 'Could not update your introduction right now.';
      });
      _showSnackBar('Could not update your introduction right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isProfileSaving = false;
        });
      }
    }
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
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const _MainFeedPage()),
                  (route) => false,
                );
              },
              child: const _BrandMark(
                assetPath: MainApp._logoAssetPath,
                width: 56,
              ),
            ),
            const SizedBox(width: 14),
            TextButton(
              onPressed: () {
                _showSnackBar('My Watchlist is coming soon on mobile.');
              },
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
            TextButton(
              onPressed: () {
                _showSnackBar('Shows is coming soon on mobile.');
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              child: const Text('Shows'),
            ),
            TextButton(
              onPressed: () {
                _showSnackBar('Movies is coming soon on mobile.');
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              child: const Text('Movies'),
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
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFECEEEA),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Introduction',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isProfileSaving
                              ? null
                              : _openEditIntroductionDialog,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _introduction,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: Color(0xFF595B61),
                        fontWeight: FontWeight.w500,
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
                accentGradient: LinearGradient(
                  colors: [Color(0xFFFBE2F0), Color(0xFFF5BDD9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                artIcon: Icons.circle,
                artColor: Color(0xFFE238A5),
              ),
              const SizedBox(height: 16),
              _ProfileListCard(
                title: 'Already Watched',
                subtitle: _formatTitleCount(alreadyWatchedCount),
                accentGradient: LinearGradient(
                  colors: [Color(0xFFDCE7F1), Color(0xFFB0D0BA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                artIcon: Icons.terrain,
                artColor: Color(0xFF355E72),
              ),
              const SizedBox(height: 16),
              _ProfileListCard(
                title: 'Favorites',
                subtitle: _formatTitleCount(0),
                accentGradient: LinearGradient(
                  colors: [Color(0xFFE0DEEE), Color(0xFFADC2F2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                artIcon: Icons.change_history,
                artColor: Color(0xFF6A7FC9),
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
  });

  final String title;
  final String subtitle;
  final Gradient accentGradient;
  final IconData artIcon;
  final Color artColor;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    Icon(artIcon, size: 46, color: artColor.withOpacity(0.75)),
                    const SizedBox(width: 14),
                    Icon(artIcon, size: 56, color: artColor.withOpacity(0.9)),
                  ],
                ),
              ),
            ),
          ],
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

class _MainFeedPage extends StatefulWidget {
  const _MainFeedPage();

  @override
  State<_MainFeedPage> createState() => _MainFeedPageState();
}

class _MainFeedPageState extends State<_MainFeedPage> {
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
      MaterialPageRoute(builder: (_) => const _CurationPage(saveOnNext: false)),
    );
  }

  void _logout() {
    AuthSession.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const _HomePage(logoAssetPath: MainApp._logoAssetPath),
      ),
      (route) => false,
    );
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                PopupMenuButton<String>(
                  tooltip: 'User menu',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 120),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: const Icon(
                      Icons.menu,
                      size: 18,
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

                  final FriendFeedItem item = _feedItems[index - 1];
                  return _FeedStatusCard(item: item);
                },
                separatorBuilder: (_, index) => index == 0
                    ? const SizedBox(height: 20)
                    : const SizedBox(height: 12),
                itemCount: _feedItems.length + 1,
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
      if (!mounted) {
        return;
      }
      setState(() {
        _results = picks;
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
      MaterialPageRoute(builder: (_) => const _CurationPage(saveOnNext: false)),
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
                    (RecommendedMovie movie) =>
                        _RecommendationCard(movie: movie),
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
  const _RecommendationCard({required this.movie});

  final RecommendedMovie movie;

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
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _MediaDetailPage(
                      imdbID: movie.imdbID,
                      title: movie.title,
                      poster: movie.poster,
                    ),
                  ),
                );
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
        : '';
    final List<String> genres = _detail?.genres ?? <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title.isEmpty ? 'Details' : title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
                          _isRemoving ? 'Removing...' : 'Remove from Watchlist',
                        ),
                      ),
                    ),
                  ],
                ],
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 36,
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SignUpInput extends StatelessWidget {
  const _SignUpInput({
    required this.hint,
    required this.controller,
    this.errorText,
    this.obscureText = false,
    this.onChanged,
  });

  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        hintStyle: const TextStyle(
          fontSize: 32,
          color: Color(0xFFB0B0B0),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC8C8C8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC8C8C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA3A3A3), width: 1.2),
        ),
      ),
      style: const TextStyle(fontSize: 30, color: Color(0xFF1F2937)),
    );
  }
}

class _TopNavigation extends StatelessWidget {
  const _TopNavigation({required this.logoAssetPath});

  final String logoAssetPath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Center(child: _BrandMark(assetPath: logoAssetPath, width: 72)),
    );
  }
}

class _BackToHomeButton extends StatelessWidget {
  const _BackToHomeButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, size: 20),
          label: const Text('Back'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF111827),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.assetPath, required this.width});

  final String assetPath;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          child: const Text(
            'Watch It',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEF5350),
            ),
          ),
        );
      },
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Text(
            'Add your logo asset\nhere',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
            ),
          ),
        );
      },
    );
  }
}
