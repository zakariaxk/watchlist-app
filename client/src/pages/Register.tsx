// Register.tsx  (route: /signup)

import { useState, useContext } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { registerUser, resendVerificationEmail } from '../api/mediaApi';
import { AuthContext } from '../context/AuthContext';
import '../styles/auth.css';

const GENRE_TILES = [
  { label: 'Adventure', gradient: 'linear-gradient(135deg, #c8e6c9, #a5d6a7, #80cbc4)' },
  { label: 'Drama', gradient: 'linear-gradient(135deg, #b2dfdb, #4db6ac, #26a69a)' },
  { label: 'Sci-Fi', gradient: 'linear-gradient(135deg, #dce775, #aed9a2, #c5e1a5)' },
  { label: 'Action', gradient: 'linear-gradient(135deg, #80deea, #c7a97b, #26c6da)' },
  { label: 'Romance', gradient: 'linear-gradient(135deg, #b3e5fc, #4fc3f7, #b0bec5)' },
  { label: 'Documentary', gradient: 'linear-gradient(135deg, #60b8f5, #a8d8ea, #e8c7c8)' },
];

// Password strength checks
const checks = [
  { label: 'At least 8 characters', test: (p: string) => p.length >= 8 },
  { label: 'One uppercase letter (A-Z)', test: (p: string) => /[A-Z]/.test(p) },
  { label: 'One lowercase letter (a-z)', test: (p: string) => /[a-z]/.test(p) },
  { label: 'One number (0-9)', test: (p: string) => /\d/.test(p) },
  { label: 'One special character (!@#$%^&*)', test: (p: string) => /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(p) },
];

const Register = () => {
  const [email, setEmail] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [resendLoading, setResendLoading] = useState(false);
  const [resendMessage, setResendMessage] = useState('');
  const [resendError, setResendError] = useState('');
  const [isVisible, setIsVisible] = useState(false);
  const context = useContext(AuthContext);
  const navigate = useNavigate();

  if (!context) return <div>Loading...</div>;
  const { login } = context;

  const allPassed = checks.every((c) => c.test(password));

  // Form submission handler
  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError('');

    if (!allPassed) {
      setError('Password does not meet all requirements.');
      return;
    }

    // Attempt registration
    setLoading(true);
    try {
      const response = await registerUser(username, email, password);
      // Note: With email verification, backend won't return token yet
      // const { user, token } = response.data;
      // login(user, token);
      // Show verification message instead
      setSubmitted(true);
    } catch (err: unknown) {
      const axiosError = err as any;
      setError(axiosError.response?.data?.message || 'Registration failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

 // Handler for resending verification email
  const handleResend = async () => {
    setResendError('');
    setResendMessage('');
    setResendLoading(true);

    try {
      const response = await resendVerificationEmail(email);
      setResendMessage(response.data.message || 'Verification email resent successfully.');
    } catch (err: unknown) {
      const axiosError = err as any;
      setResendError(axiosError.response?.data?.message || 'Failed to resend verification email.');
    } finally {
      setResendLoading(false);
    }
  };


  return (
    <div className="auth-page signup-page">
      <div className="auth-form-wrap">
        <h1 className="auth-title">Sign Up</h1>

        {error && <div className="auth-error">{error}</div>}

        {!submitted ? (
          <form onSubmit={handleSubmit} className="auth-form">
            <div className="auth-field">
              <label>Email</label>
              <input
                type="email"
                placeholder="you@email.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                disabled={loading}
                autoComplete="email"
              />
            </div>

            <div className="auth-field">
              <label>Username</label>
              <input
                type="text"
                placeholder="Username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                disabled={loading}
                autoComplete="username"
              />
            </div>

            <div className="auth-field">
              <label>Password</label>
              <div className="pw-wrap">
                <input
                  type={showPw ? 'text' : 'password'}
                  placeholder="Password"
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
                  {showPw ? (
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
                      <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
                      <line x1="1" y1="1" x2="23" y2="23"/>
                    </svg>
                  ) : (
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                      <circle cx="12" cy="12" r="3"/>
                    </svg>
                  )}
                </button>
              </div>

              {/* Password strength checklist — only shown when user starts typing */}
              {password.length > 0 && (
                <ul className="pw-checklist">
                  {checks.map((c) => (
                    <li key={c.label} className={c.test(password) ? 'pw-check-pass' : 'pw-check-fail'}>
                      <span className="pw-check-icon">{c.test(password) ? '✓' : '✗'}</span>
                      {c.label}
                    </li>
                  ))}
                </ul>
              )}
            </div>

            <button onClick={() => setIsVisible(true)} type="submit" disabled={loading || !allPassed} className="auth-submit-btn">
              {loading ? 'Creating account...' : 'Submit'}
            </button>
          </form>
        ) : (
          <div className="auth-success">
            <p>Verification email sent! Please check your email and click the link to verify your account.</p>
            <p>If you did not receive it, click the button below to resend.</p>
            {resendError && <div className="auth-error">{resendError}</div>}
            {resendMessage && <div className="auth-success">{resendMessage}</div>}
            <button
              type="button"
              className="auth-submit-btn"
              onClick={handleResend}
              disabled={resendLoading || loading || !email}
            >
              {resendLoading ? 'Resending…' : 'Resend verification email'}
            </button>
            <div style={{ marginTop: '1rem' }}>
              <Link to="/login">Back to Login</Link>
            </div>
          </div>
        )}

        {!submitted && (
          <p className="auth-switch">
            Already have an account? <Link to="/login">Log In</Link>
          </p>
        )}
      </div>

      {/* ── "Choose what you want to watch" section ── */}
      {!submitted && isVisible && (
        <section>
      <div className="signup-genre-section">
        <h2 className="signup-genre-title">Choose what you want to watch</h2>
        <p className="signup-genre-sub">This is what makes WatchIt! personalised to you.</p>
        <div className="signup-genre-grid">
          {GENRE_TILES.map((tile) => (
            <div
              key={tile.label}
              className="signup-genre-tile"
              style={{ background: tile.gradient }}
            />
          ))}
        </div>
        <div className="signup-next-wrap">
          <Link to="/" className="signup-next-link">Next</Link>
        </div>
      </div>
      </section>
    )}

    </div>
  );
};

export default Register;
