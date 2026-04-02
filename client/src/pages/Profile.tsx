// hsp - Profile.tsx  (route: /profile)
// Matches the /profile mockup: clean white page, large "My Profile" heading,
// lots of whitespace. Includes:
//   - Profile info (username, email, visibility toggle + save)
//   - Watchlist link
//   - User search (search other users by username, debounced, min 2 chars)
//   - Public/private profile notice

import { useState, useEffect, useContext, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { AuthContext } from '../context/AuthContext';
import {
  getProfile, updateProfile, searchUsers,
  UserProfile, PublicUser,
  getFriends, FriendUser, unfollowUser,
} from '../api/mediaApi';
import '../styles/profile.css';

const DEBOUNCE_MS = 400;
const MIN_SEARCH_CHARS = 2;

const Profile = () => {
  const context = useContext(AuthContext);
  const navigate = useNavigate();

  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [visibility, setVisibility] = useState('public');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  // User search state
  const [userQuery, setUserQuery] = useState('');
  const [userResults, setUserResults] = useState<PublicUser[]>([]);
  const [userSearching, setUserSearching] = useState(false);

  // Friends list state
  const [friends, setFriends] = useState<FriendUser[]>([]);
  const [friendsLoading, setFriendsLoading] = useState(true);

  const messageTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  if (!context) return <div>Loading...</div>;

  // Fetch own profile on mount
  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const res = await getProfile();
        setProfile(res.data);
        setVisibility(res.data.profileVisibility);
      } catch {
        setMessage('Failed to load profile');
      } finally {
        setLoading(false);
      }
    };
    fetchProfile();
  }, []);

  // Fetch friends list on mount
  useEffect(() => {
    getFriends()
      .then((res) => setFriends(res.data))
      .catch(() => setFriends([]))
      .finally(() => setFriendsLoading(false));
  }, []);

  // Debounced user search
  useEffect(() => {
    if (userQuery.length < MIN_SEARCH_CHARS) {
      setUserResults([]);
      return;
    }
    const timer = setTimeout(async () => {
      setUserSearching(true);
      try {
        const res = await searchUsers(userQuery);
        setUserResults(res.data.users);
      } catch {
        setUserResults([]);
      } finally {
        setUserSearching(false);
      }
    }, DEBOUNCE_MS);
    return () => clearTimeout(timer);
  }, [userQuery]);

  const handleSave = async () => {
    setSaving(true);
    setMessage('');
    try {
      const res = await updateProfile({ profileVisibility: visibility });
      setProfile(res.data.user);
      setMessage('Profile updated!');
    } catch {
      setMessage('Failed to update profile');
    } finally {
      setSaving(false);
      if (messageTimer.current) clearTimeout(messageTimer.current);
      messageTimer.current = setTimeout(() => setMessage(''), 3000);
    }
  };

  const handleUnfollow = async (friendId: string) => {
    try {
      await unfollowUser(friendId);
      setFriends((prev) => prev.filter((f) => f._id !== friendId));
    } catch {
      // silently fail
    }
  };

  if (loading) return <div className="loading">Loading profile...</div>;

  return (
    <div className="profile-page">
      {/* Large heading matching mockup */}
      <h1 className="profile-heading">My Profile</h1>

      {/* Profile info card */}
      {profile && (
        <div className="profile-card">
          <div className="profile-info-row">
            <span className="profile-info-label">Username</span>
            <span className="profile-info-value">{profile.username}</span>
          </div>
          <div className="profile-info-row">
            <span className="profile-info-label">Email</span>
            <span className="profile-info-value">{profile.email}</span>
          </div>

          {/* Profile visibility control */}
          <div className="profile-visibility-wrap">
            <label className="profile-info-label" htmlFor="visibility-select">
              Profile Visibility
            </label>
            <select
              id="visibility-select"
              value={visibility}
              onChange={(e) => setVisibility(e.target.value)}
              className="profile-select"
            >
              <option value="public">Public</option>
              <option value="private">Private</option>
            </select>
          </div>

          <button
            onClick={handleSave}
            disabled={saving}
            className="profile-save-btn"
          >
            {saving ? 'Saving...' : 'Save changes'}
          </button>

          {message && (
            <p
              className={
                message.includes('Failed') ? 'profile-msg profile-msg-error' : 'profile-msg profile-msg-ok'
              }
            >
              {message}
            </p>
          )}
        </div>
      )}

      {/* Watchlist shortcut link — skip, nav already has "My Watchlist" */}

      {/* ── Friends (following) section ──────────────── */}
      <div className="profile-section">
        <h2 className="profile-section-heading">
          People I Follow
          {!friendsLoading && <span className="profile-friend-count">{friends.length}</span>}
        </h2>
        {friendsLoading ? (
          <p className="profile-search-hint">Loading...</p>
        ) : friends.length === 0 ? (
          <p className="profile-search-hint">You're not following anyone yet. Use "Find People" below.</p>
        ) : (
          <ul className="profile-user-results">
            {friends.map((f) => (
              <li key={f._id} className="profile-user-result-item">
                <button
                  className="profile-user-result-btn"
                  onClick={() => navigate(`/users/${f._id}`)}
                >
                  <span className="profile-user-result-name">{f.username}</span>
                  {f.profileVisibility === 'private' && (
                    <span className="profile-user-private-badge">Private</span>
                  )}
                </button>
                <button
                  className="profile-unfollow-btn"
                  onClick={() => handleUnfollow(f._id)}
                  title="Unfollow"
                >
                  Unfollow
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* ── User search section ──────────────────────── */}
      <div className="profile-section">
        <h2 className="profile-section-heading">Find People</h2>
        <input
          type="text"
          placeholder="Search users by username..."
          value={userQuery}
          onChange={(e) => setUserQuery(e.target.value)}
          className="profile-user-search-input"
        />
        {userQuery.length > 0 && userQuery.length < MIN_SEARCH_CHARS && (
          <p className="profile-search-hint">Type at least {MIN_SEARCH_CHARS} characters to search.</p>
        )}
        {userSearching && <p className="profile-search-hint">Searching...</p>}

        {/* Search results list */}
        {userResults.length > 0 && (
          <ul className="profile-user-results">
            {userResults.map((u) => (
              <li key={u._id} className="profile-user-result-item">
                <button
                  className="profile-user-result-btn"
                  onClick={() => navigate(`/users/${u._id}`)}
                >
                  <span className="profile-user-result-name">{u.username}</span>
                  {u.profileVisibility === 'private' && (
                    <span className="profile-user-private-badge">Private</span>
                  )}
                </button>
              </li>
            ))}
          </ul>
        )}

        {/* No results state */}
        {!userSearching && userQuery.length >= MIN_SEARCH_CHARS && userResults.length === 0 && (
          <p className="profile-search-hint">No users found.</p>
        )}
      </div>
    </div>
  );
};

export default Profile;

