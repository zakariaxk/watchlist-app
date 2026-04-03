import 'dart:math' as math;

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
                            builder: (_) => const _CurationPage(),
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
        MaterialPageRoute(builder: (_) => const _CurationPage()),
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _serverError = error.message;
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

class _CurationPage extends StatelessWidget {
  const _CurationPage();

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
                  'This is what makes WatchIt! personalized to you',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 26),
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
                  overlay: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: RadialGradient(
                        center: const Alignment(-0.5, -0.4),
                        radius: 0.9,
                        colors: [
                          Colors.white.withValues(alpha: 0.32),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _CurationTile(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFC5DDD7),
                      Color(0xFFB6D9D4),
                      Color(0xFF2CBFE9),
                      Color(0xFFC9934B),
                      Color(0xFF857659),
                    ],
                    stops: [0.0, 0.35, 0.55, 0.78, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                const SizedBox(height: 18),
                _CurationTile(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9DBEC0), Color(0xFF94B8B8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  overlay: CustomPaint(painter: _LeafStrokePainter()),
                ),
                const SizedBox(height: 18),
                _CurationTile(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF9ED7D7),
                      Color(0xFFBBD3F2),
                      Color(0xFF8FCED2),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  overlay: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const RadialGradient(
                        center: Alignment.center,
                        radius: 0.55,
                        colors: [Color(0xFF4A99BE), Color(0x004A99BE)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _CurationTile(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF9CCDC7),
                      Color(0xFFA9D3F5),
                      Color(0xFFB7BA6A),
                      Color(0xFFA8A48F),
                      Color(0xFFA9D4CE),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                const SizedBox(height: 18),
                _CurationTile(
                  gradient: const RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.0,
                    colors: [
                      Color(0xFF9BC8C2),
                      Color(0xFF84B8B5),
                      Color(0xFF40A6DA),
                      Color(0xFF77C9CF),
                    ],
                  ),
                  overlay: CustomPaint(painter: _SunburstPainter()),
                ),
                const SizedBox(height: 34),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text(
                      'Next',
                      style: TextStyle(
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

class _LeafStrokePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF4B94B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final Path left = Path()
      ..moveTo(-12, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.92,
        size.width * 0.38,
        size.height * 0.98,
      );

    final Path middle = Path()
      ..moveTo(size.width * 0.36, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.85,
        size.width * 0.68,
        size.height * 0.98,
      );

    final Path right = Path()
      ..moveTo(size.width * 0.78, size.height * 0.26)
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.58,
        size.width * 0.73,
        size.height * 0.98,
      );

    final Path farRight = Path()
      ..moveTo(size.width * 1.02, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.58,
        size.width * 0.82,
        size.height * 0.98,
      );

    canvas.drawPath(left, paint);
    canvas.drawPath(middle, paint);
    canvas.drawPath(right, paint);
    canvas.drawPath(farRight, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SunburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint rayPaint = Paint()
      ..color = const Color(0xFF2F86E2).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final Offset center = Offset(size.width / 2, size.height * 0.34);
    const int rays = 14;
    for (int i = 0; i < rays; i++) {
      final double angle = (i / rays) * 3.14159265359 * 2;
      final Path ray = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + 220 * math.cos(angle - 0.1),
          center.dy + 220 * math.sin(angle - 0.1),
        )
        ..lineTo(
          center.dx + 220 * math.cos(angle + 0.1),
          center.dy + 220 * math.sin(angle + 0.1),
        )
        ..close();
      canvas.drawPath(ray, rayPaint);
    }

    final Paint fade = Paint()
      ..shader = const RadialGradient(
        radius: 0.9,
        colors: [Color(0x0098C8C4), Color(0xCC98C8C4)],
      ).createShader(Rect.fromCircle(center: center, radius: 240));
    canvas.drawRect(Offset.zero & size, fade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
