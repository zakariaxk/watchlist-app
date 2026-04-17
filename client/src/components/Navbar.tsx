// hsp - Navbar.tsx
// Compact top navbar matching WatchIt mockups.
// Logged-out: Sign Up | Log In | Shows | Films + search bar on right
// Logged-in:  My Profile | Log Out | Shows | Films + search bar on right
// The search bar is a mini inline search (debounced, min 3 chars) that
// navigates to /search?q=... on submit or result click.

import { useContext, useState, useEffect, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { AuthContext } from '../context/AuthContext';
import { searchMedia, OmdbSearchResult } from '../api/mediaApi';
import mini_logo from '../assets/images/watchit_minilogo.png';
import '../styles/navbar.css';

const MIN_CHARS = 3;
const DEBOUNCE_MS = 450;

const Navbar = () => {
  const context = useContext(AuthContext);
  const navigate = useNavigate();

  // Inline navbar search state
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<OmdbSearchResult[]>([]);
  const [searching, setSearching] = useState(false);
  const wrapperRef = useRef<HTMLDivElement>(null);

  if (!context) return null;

  const { isAuthenticated, logout } = context;

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  // Debounced search — fires only when >= MIN_CHARS typed
  useEffect(() => {
    if (query.length < MIN_CHARS) {
      setResults([]);
      return;
    }
    const timer = setTimeout(async () => {
      setSearching(true);
      try {
        const res = await searchMedia(query);
        // Show first 6 results in dropdown
        setResults(res.data.results.slice(0, 6));
      } catch {
        setResults([]);
      } finally {
        setSearching(false);
      }
    }, DEBOUNCE_MS);
    return () => clearTimeout(timer);
  }, [query]);

  // Close dropdown on outside click
  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target as Node)) {
        setResults([]);
      }
    };
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  const handleResultClick = (imdbID: string) => {
    setQuery('');
    setResults([]);
    navigate(`/media/${imdbID}`);
  };

  // Full search on Enter key or search button
  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (query.trim().length >= MIN_CHARS) {
      const q = query.trim();
      setQuery('');
      setResults([]);
      navigate(`/search?q=${encodeURIComponent(q)}`);
    }
  };

  return (
    <nav className="navbar">
      <div className="navbar-container">
        <Link to="/" className="navbar-logo" aria-label="WatchIt home">
          <img src={mini_logo} alt="WatchIt" className = "fit-logo-image"/>
        </Link>

        {/* Left-side nav links */}
        <div className="navbar-links">
          {isAuthenticated ? (
            <>
              <Link to="/profile" className="nav-link">My Profile</Link>
              <Link to="/watchlist" className="nav-link">My Watchlist</Link>
              
            </>
          ) : (
            <>
              <Link to="/signup" className="nav-link">Sign Up</Link>
              <Link to="/login" className="nav-link">Log In</Link>
            </>
          )}
          <Link to="/shows" className="nav-link">Shows</Link>
          <Link to="/films" className="nav-link">Movies</Link>
        </div>

        {/* Right-side rounded search bar */}
        <div className="navbar-search-wrapper" ref={wrapperRef}>
          <form className="navbar-search" onSubmit={handleSearchSubmit}>
            <input
              className="navbar-search-input"
              type="text"
              placeholder="Search Movies and Shows"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              aria-label="Search"
            />
            <button type="submit" className="navbar-search-btn" aria-label="Submit search">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="11" cy="11" r="8"/>
                <path d="m21 21-4.35-4.35"/>
              </svg>
            </button>
          </form>

          {/* Inline dropdown results */}
          {query.length > 0 && (
            <div className="navbar-search-results">
              {query.length < MIN_CHARS ? (
                <p className="navbar-search-hint">
                  Type at least {MIN_CHARS} characters to search.
                </p>
              ) : searching ? (
                <p className="navbar-search-hint">Searching...</p>
              ) : results.length === 0 ? (
                <p className="navbar-search-hint">No results found.</p>
              ) : (
                results.map((item) => (
                  <div
                    key={item.imdbID}
                    className="navbar-search-result-item"
                    onClick={() => handleResultClick(item.imdbID)}
                  >
                    {/* Poster thumbnail or fallback */}
                    {item.poster && item.poster !== 'N/A' ? (
                      <img
                        src={item.poster}
                        alt={item.title}
                        className="navbar-search-result-img"
                      />
                    ) : (
                      <div
                        className="navbar-search-result-img"
                        style={{ background: '#e9ecef' }}
                      />
                    )}
                    <span>{item.title} {item.year ? `(${item.year})` : ''}</span>
                  </div>
                ))
              )}
            </div>
          )}
        </div>
        {isAuthenticated && (
          <button onClick={handleLogout} className="nav-link-logout">Log Out</button>
        )}
      </div>
    </nav>
  );
};

export default Navbar;

