import { useContext } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { AuthContext } from '../context/AuthContext';
import '../styles/navbar.css';

const Navbar = () => {
  const context = useContext(AuthContext);
  const navigate = useNavigate();

  if (!context) {
    return <nav>Loading...</nav>;
  }

  const { isAuthenticated, user, logout } = context;

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <nav className="navbar">
      <div className="navbar-container">
        <Link to="/" className="navbar-logo">
          Watchlist App
        </Link>
        <div className="navbar-menu">
          {isAuthenticated ? (
            <>
              <Link to="/" className="nav-link">
                Home
              </Link>
              <Link to="/watchlist" className="nav-link">
                My Watchlist
              </Link>
              <Link to="/search" className="nav-link">
                Search
              </Link>
              <Link to="/profile" className="nav-link">
                Profile
              </Link>
              <span className="nav-user">Welcome, {user?.username}</span>
              <button onClick={handleLogout} className="nav-btn logout-btn">
                Logout
              </button>
            </>
          ) : (
            <>
              <Link to="/login" className="nav-link">
                Login
              </Link>
              <Link to="/register" className="nav-link">
                Register
              </Link>
            </>
          )}
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
