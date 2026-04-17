import { useMemo, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { resetPassword } from '../api/mediaApi';
import { isPasswordStrong, passwordStrengthChecks } from '../utils/validation';
import '../styles/auth.css';

const ResetPassword = () => {
  const [searchParams] = useSearchParams();
  const token = useMemo(() => searchParams.get('token') || '', [searchParams]);

  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [showConfirmPw, setShowConfirmPw] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  const allPassed = isPasswordStrong(password);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError('');
    setMessage('');

    if (!token) {
      setError('Reset token is missing. Please request a new password reset link.');
      return;
    }

    if (!allPassed) {
      setError('Password does not meet all requirements.');
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    setLoading(true);
    try {
      const response = await resetPassword(token, password);
      setMessage(response.data.message || 'Password reset successful. You can now log in.');
      setPassword('');
      setConfirmPassword('');
    } catch (err: unknown) {
      const axiosError = err as any;
      setError(axiosError.response?.data?.message || 'Unable to reset password. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page">
      <div className="auth-form-wrap">
        <h1 className="auth-title">Reset Password</h1>

        {error && <div className="auth-error">{error}</div>}
        {message && <div className="auth-success">{message}</div>}

        <form onSubmit={handleSubmit} className="auth-form">
          <div className="auth-field">
            <label>New Password</label>
            <div className="pw-wrap">
              <input
                type={showPw ? 'text' : 'password'}
                placeholder="New password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                disabled={loading}
                autoComplete="new-password"
              />
              <button
                type="button"
                className="pw-toggle"
                onClick={() => setShowPw((v) => !v)}
                tabIndex={-1}
                aria-label={showPw ? 'Hide password' : 'Show password'}
              >
                {showPw ? 'Hide' : 'Show'}
              </button>
            </div>

            {password.length > 0 && (
              <ul className="pw-checklist">
                {passwordStrengthChecks.map((c) => (
                  <li key={c.label} className={c.test(password) ? 'pw-check-pass' : 'pw-check-fail'}>
                    <span className="pw-check-icon">{c.test(password) ? '✓' : '✗'}</span>
                    {c.label}
                  </li>
                ))}
              </ul>
            )}
          </div>

          <div className="auth-field">
            <label>Confirm New Password</label>
            <div className="pw-wrap">
              <input
                type={showConfirmPw ? 'text' : 'password'}
                placeholder="Confirm new password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
                disabled={loading}
                autoComplete="new-password"
              />
              <button
                type="button"
                className="pw-toggle"
                onClick={() => setShowConfirmPw((v) => !v)}
                tabIndex={-1}
                aria-label={showConfirmPw ? 'Hide password' : 'Show password'}
              >
                {showConfirmPw ? 'Hide' : 'Show'}
              </button>
            </div>
          </div>

          <button type="submit" disabled={loading || !allPassed} className="auth-submit-btn">
            {loading ? 'Resetting...' : 'Reset Password'}
          </button>
        </form>

        <p className="auth-switch">
          Back to <Link to="/login">Log In</Link>
        </p>
      </div>
    </div>
  );
};

export default ResetPassword;
