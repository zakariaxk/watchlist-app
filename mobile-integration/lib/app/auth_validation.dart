class PasswordRequirement {
  const PasswordRequirement({required this.label, required this.test});

  final String label;
  final bool Function(String password) test;
}

class AuthValidation {
  static final RegExp _emailFormatRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static const List<PasswordRequirement> passwordRequirements =
      <PasswordRequirement>[
        PasswordRequirement(
          label: 'At least 8 characters',
          test: _hasMinLength,
        ),
        PasswordRequirement(
          label: 'One uppercase letter (A-Z)',
          test: _hasUppercase,
        ),
        PasswordRequirement(
          label: 'One lowercase letter (a-z)',
          test: _hasLowercase,
        ),
        PasswordRequirement(label: 'One number (0-9)', test: _hasNumber),
        PasswordRequirement(
          label: 'One special character (!@#\$%^&*)',
          test: _hasSpecialCharacter,
        ),
      ];

  static bool isEmailFormatValid(String email) {
    return _emailFormatRegex.hasMatch(email);
  }

  static bool isPasswordStrong(String password) {
    return passwordRequirements.every(
      (PasswordRequirement requirement) => requirement.test(password),
    );
  }

  static bool _hasMinLength(String password) => password.length >= 8;

  static bool _hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);

  static bool _hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);

  static bool _hasNumber(String password) => RegExp(r'\d').hasMatch(password);

  static bool _hasSpecialCharacter(String password) {
    return RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]''').hasMatch(password);
  }
}
