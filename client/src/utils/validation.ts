export type PasswordStrengthCheck = {
  label: string;
  test: (password: string) => boolean;
};

const EMAIL_FORMAT_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const isEmailFormatValid = (email: string): boolean => {
  return EMAIL_FORMAT_REGEX.test(email);
};

export const passwordStrengthChecks: PasswordStrengthCheck[] = [
  { label: 'At least 8 characters', test: (password: string) => password.length >= 8 },
  { label: 'One uppercase letter (A-Z)', test: (password: string) => /[A-Z]/.test(password) },
  { label: 'One lowercase letter (a-z)', test: (password: string) => /[a-z]/.test(password) },
  { label: 'One number (0-9)', test: (password: string) => /\d/.test(password) },
  { label: 'One special character (!@#$%^&*)', test: (password: string) => /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]/.test(password) },
];

export const isPasswordStrong = (password: string): boolean => {
  return passwordStrengthChecks.every((check) => check.test(password));
};