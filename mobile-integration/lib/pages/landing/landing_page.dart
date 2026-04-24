import 'package:flutter/material.dart';

import '../../app/auth_validation.dart';
import '../../auth_api.dart';
import '../../widgets/brand_mark.dart';
import '../profile/curation_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.logoAssetPath});

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
                                const CurationPage(saveOnNext: true),
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
    final String password = _passwordController.text;

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

      Navigator.of(context).pushReplacementNamed('/feed');
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
    final String password = _passwordController.text;

    String? nextEmailError;
    String? nextUsernameError;
    String? nextPasswordError;

    if (email.isEmpty) {
      nextEmailError = 'Email is required';
    } else if (!AuthValidation.isEmailFormatValid(email)) {
      nextEmailError = 'Please enter a valid email address.';
    }
    if (username.isEmpty) {
      nextUsernameError = 'Username is required';
    }
    if (password.isEmpty) {
      nextPasswordError = 'Password is required';
    } else if (!AuthValidation.isPasswordStrong(password)) {
      nextPasswordError = 'Password does not meet all requirements.';
    }

    setState(() {
      _emailError = nextEmailError;
      _usernameError = nextUsernameError;
      _passwordError = nextPasswordError;
      _serverError = null;
    });

    if (nextEmailError != null ||
        nextUsernameError != null ||
        nextPasswordError != null) {
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
    } catch (_) {
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
    final String password = _passwordController.text;
    final bool allPasswordRequirementsPassed = AuthValidation.isPasswordStrong(
      password,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(text: 'Email'),
        const SizedBox(height: 10),
        _SignUpInput(
          hint: 'xxx@email.com',
          controller: _emailController,
          errorText: _emailError,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            if (_emailError != null) {
              setState(() {
                _emailError = value.trim().isEmpty
                    ? 'Email is required'
                    : AuthValidation.isEmailFormatValid(value.trim())
                    ? null
                    : 'Please enter a valid email address.';
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
            setState(() {
              if (_passwordError != null) {
                _passwordError = value.isEmpty
                    ? 'Password is required'
                    : AuthValidation.isPasswordStrong(value)
                    ? null
                    : 'Password does not meet all requirements.';
              }
            });
          },
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...AuthValidation.passwordRequirements.map((
            PasswordRequirement requirement,
          ) {
            final bool passed = requirement.test(password);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    passed ? Icons.check : Icons.close,
                    size: 18,
                    color: passed
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      requirement.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: passed
                            ? const Color(0xFF15803D)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting || !allPasswordRequirementsPassed
                ? null
                : _submit,
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
    this.keyboardType,
  });

  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
      child: Center(child: BrandMark(assetPath: logoAssetPath, width: 72)),
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
