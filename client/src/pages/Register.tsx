// hsp - Register.tsx  (route: /signup)
// Matches the signup mockup:
//  1. Compact centered "Sign Up" form at the top (Email, Username, Password)
//  2. "Choose what you want to watch" section below with a 3x2 tile grid
//  3. Centered "Next" link below the grid
// Route kept at /signup (App.tsx will add this route alias)

import { useState, useContext } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { registerUser } from '../api/mediaApi';
import { AuthContext } from '../context/AuthContext';
import '../styles/auth.css';

// Gradient tile placeholders matching mockup color swatches
const GENRE_TILES = [
  { label: 'Adventure', gradient: 'linear-gradient(135deg, #c8e6c9, #a5d6a7, #80cbc4)' },
  { label: 'Drama', gradient: 'linear-gradient(135deg, #b2dfdb, #4db6ac, #26a69a)' },
  { label: 'Sci-Fi', gradient: 'linear-gradient(135deg, #dce775, #aed9a2, #c5e1a5)' },
  { label: 'Action', gradient: 'linear-gradient(135deg, #80deea, #c7a97b, #26c6da)' },
  { label: 'Romance', gradient: 'linear-gradient(135deg, #b3e5fc, #4fc3f7, #b0bec5)' },
  { label: 'Documentary', gradient: 'linear-gradient(135deg, #60b8f5, #a8d8ea, #e8c7c8)' },
];

const Register = () => {
  const [email, setEmail] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const context = useContext(AuthContext);
  const navigate = useNavigate();

  if (!context) return <div>Loading...</div>;

  const { login } = context;

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError('');

    if (password.length < 6) {
      setError('Password must be at least 6 characters');
      return;
    }

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

  return (
    <div className="auth-page signup-page">
      {/* ── Sign Up form ─────────────────────────────── */}
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
              <input
                type="password"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                disabled={loading}
                autoComplete="new-password"
              />
            </div>

            <button type="submit" disabled={loading} className="auth-submit-btn">
              {loading ? 'Creating account...' : 'Submit'}
            </button>
          </form>
        ) : (
          <div className="auth-success">
            <p>Verification email sent! Please check your email and click the link to verify your account.</p>
            <p>You can close this page and return after verification.</p>
          </div>
        )}

        {!submitted && (
          <p className="auth-switch">
            Already have an account? <Link to="/login">Log In</Link>
          </p>
        )}
      </div>

      {/* ── "Choose what you want to watch" section ── */}
      {!submitted && (
      <div className="signup-genre-section">
        <h2 className="signup-genre-title">Choose what you want to watch</h2>
        <p className="signup-genre-sub">
          This is what makes WatchIt! personalised to you.
        </p>

        {/* 3-column × 2-row tile grid */}
        <div className="signup-genre-grid">
          {GENRE_TILES.map((tile) => (
            <div
              key={tile.label}
              className="signup-genre-tile"
              style={{ background: tile.gradient }}
            />
          ))}
        </div>

        {/* Centered "Next" navigation */}
        <div className="signup-next-wrap">
          <Link to="/" className="signup-next-link">
            Next
          </Link>
        </div>
      </div>
    )}
    </div>
  );
};

export default Register;

