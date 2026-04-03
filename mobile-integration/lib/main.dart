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

  Future<void> _submitGenres() async {
    if (_selectedGenres.isEmpty) {
      setState(() {
        _serverError = 'Pick at least one genre to continue.';
      });
      return;
    }

    if (!widget.saveOnNext) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const _MainFeedPage()),
        (route) => false,
      );
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

  @override
  Widget build(BuildContext context) {
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
                    if (value == 'logout') {
                      _logout();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      const <PopupMenuEntry<String>>[
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
                      'Select genres to start getting movie picks.',
                      style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                    )
                  else
                    ..._recommendedMovies
                        .map(
                          (RecommendedMovie movie) =>
                              _RecommendationCard(movie: movie),
                        )
                        .toList(),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemBuilder: (BuildContext context, int index) {
                  final FriendFeedItem item = _feedItems[index];
                  return _FeedStatusCard(item: item);
                },
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemCount: _feedItems.length,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: movie.poster != null && movie.poster!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  movie.poster!,
                  width: 44,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.movie),
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
          movie.year.isEmpty ? 'Movie' : movie.year,
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
