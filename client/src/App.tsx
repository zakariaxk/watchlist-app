// hsp - App.tsx
// Router configuration.
// New routes added:
//   /signup      → Register page (was /register; /register redirects here)
//   /films       → Films genre browse page
//   /shows       → Shows genre browse page
//   /show_genre  → ShowGenre page
//   /users/:userId → Public user profile view

import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import Navbar from './components/Navbar';
import ProtectedRoute from './components/ProtectedRoute';
import Home from './pages/Home';
import Login from './pages/Login';
import Register from './pages/Register';
import Watchlist from './pages/Watchlist';
import MediaDetail from './pages/MediaDetail';
import Search from './pages/Search';
import Profile from './pages/Profile';
import Films from './pages/Films';
import Shows from './pages/Shows';
import ShowGenre from './pages/ShowGenre';
import GenreResults from './pages/GenreResults';
import UserPublicProfile from './pages/UserPublicProfile';
import './styles/main.css';

function App() {
  return (
    <Router>
      <AuthProvider>
        <Navbar />
        <Routes>
          {/* Auth pages */}
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Register />} />
          {/* Keep /register as an alias so existing links don't break */}
          <Route path="/register" element={<Navigate to="/signup" replace />} />

          {/* Public pages */}
          <Route path="/" element={<Home />} />
          <Route path="/films" element={<Films />} />
          <Route path="/shows" element={<Shows />} />
          <Route path="/show_genre" element={<ShowGenre />} />
          <Route path="/genre" element={<GenreResults />} />
          <Route path="/search" element={<Search />} />
          <Route path="/media/:id" element={<MediaDetail />} />

          {/* Public user profile view */}
          <Route path="/users/:userId" element={<UserPublicProfile />} />

          {/* Protected pages — require login */}
          <Route
            path="/watchlist"
            element={
              <ProtectedRoute>
                <Watchlist />
              </ProtectedRoute>
            }
          />
          <Route
            path="/profile"
            element={
              <ProtectedRoute>
                <Profile />
              </ProtectedRoute>
            }
          />

          {/* Fallback */}
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      </AuthProvider>
    </Router>
  );
}

export default App;

