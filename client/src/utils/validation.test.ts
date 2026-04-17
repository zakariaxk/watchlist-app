import { describe, expect, it } from 'vitest';
import { isEmailFormatValid, isPasswordStrong } from './validation';

describe('isEmailFormatValid', () => {
  it('accepts a valid normal email', () => {
    expect(isEmailFormatValid('student@example.com')).toBe(true);
  });

  it('accepts a valid email with numbers', () => {
    expect(isEmailFormatValid('student2026@watchlist123.com')).toBe(true);
  });

  it('rejects an email missing @', () => {
    expect(isEmailFormatValid('student.example.com')).toBe(false);
  });

  it('rejects an email missing domain', () => {
    expect(isEmailFormatValid('student@')).toBe(false);
  });

  it('rejects an email missing username', () => {
    expect(isEmailFormatValid('@example.com')).toBe(false);
  });

  it('rejects an empty string', () => {
    expect(isEmailFormatValid('')).toBe(false);
  });

  it('rejects whitespace-only input', () => {
    expect(isEmailFormatValid('   ')).toBe(false);
  });

  it('rejects malformed email format', () => {
    expect(isEmailFormatValid('student@@example..com')).toBe(false);
  });
});

describe('isPasswordStrong', () => {
  it('accepts a valid strong password', () => {
    expect(isPasswordStrong('StrongPass1!')).toBe(true);
  });

  it('rejects a password that is too short', () => {
    expect(isPasswordStrong('Aa1!abc')).toBe(false);
  });

  it('rejects a password missing uppercase letters', () => {
    expect(isPasswordStrong('strongpass1!')).toBe(false);
  });

  it('rejects a password missing lowercase letters', () => {
    expect(isPasswordStrong('STRONGPASS1!')).toBe(false);
  });

  it('rejects a password missing a number', () => {
    expect(isPasswordStrong('StrongPass!')).toBe(false);
  });

  it('rejects a password missing a special character', () => {
    expect(isPasswordStrong('StrongPass1')).toBe(false);
  });

  it('rejects an empty string', () => {
    expect(isPasswordStrong('')).toBe(false);
  });

  it('rejects whitespace-only input', () => {
    expect(isPasswordStrong('        ')).toBe(false);
  });
});