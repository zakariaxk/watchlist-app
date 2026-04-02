// UserPublicProfile.tsx  (route: /users/:userId)
// Shows a public profile with follow/unfollow button.
// If public: shows username, join date, and their watchlist.
// If private: shows "This profile is private."

import { useState, useEffect, useContext } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  getPublicUser,
  PublicUser,
  getWatchlist,
  WatchlistItem,
  checkFollowing,
  followUser,
  unfollowUser,
} from '../api/mediaApi';
import { AuthContext } from '../context/AuthContext';
import '../styles/profile.css';

const statusLabel = (s: string) => {
  if (s === 'plan_to_watch') return 'Plan to Watch';
  if (s === 'watching') return 'Watching';
  if (s === 'completed') return 'Completed';
  return s;
};

const UserPublicProfile = () => {
  const { userId } = useParams<{ userId: string }>();
  const navigate = useNavigate();
  const context = useContext(AuthContext);
  const currentUser = context?.user;

  const [user, setUser] = useState<PublicUser | null>(null);
  const [watchlist, setWatchlist] = useState<WatchlistItem[]>([]);
  const [following, setFollowing] = useState(false);
  const [followLoading, setFollowLoading] = useState(false);
  const [pageLoading, setPageLoading] = useState(true);
  const [error, setError] = useState('');
  const [followMsg, setFollowMsg] = useState('');

  useEffect(() => {
    if (!userId) return;
    const load = async () => {
      try {
        const res = await getPublicUser(userId);
        setUser(res.data);

        // Load their watchlist if profile is public
        if (res.data.profileVisibility === 'public') {
          const wRes = await getWatchlist(userId);
          setWatchlist(wRes.data);
        }

        // Check follow status only when logged in and not viewing own profile
        if (currentUser && currentUser._id !== userId) {
          const fRes = await checkFollowing(userId);
          setFollowing(fRes.data.following);
        }
      } catch {
        setError('User not found.');
      } finally {
        setPageLoading(false);
      }
    };
    load();
  }, [userId]);

  const handleFollow = async () => {
    if (!userId) return;
    setFollowLoading(true);
    try {
      if (following) {
        await unfollowUser(userId);
        setFollowing(false);
        setFollowMsg('Unfollowed.');
      } else {
        await followUser(userId);
        setFollowing(true);
        setFollowMsg('Now following!');
      }
    } catch (err: any) {
      setFollowMsg(err.response?.data?.message || 'Action failed.');
    } finally {
      setFollowLoading(false);
      setTimeout(() => setFollowMsg(''), 3000);
    }
  };

  if (pageLoading) return <div className="loading">Loading...</div>;
  if (error) return <div className="profile-page"><p className="profile-search-hint">{error}</p></div>;
  if (!user) return null;

  const isOwnProfile = currentUser?._id === userId;

  return (
    <div className="profile-page">
      <button className="profile-back-btn" onClick={() => navigate(-1)}>← Back</button>

      <div className="pub-profile-header">
        <h1 className="profile-heading">{user.username}</h1>

        {/* Follow button — only shown to logged-in users viewing someone else's profile */}
        {currentUser && !isOwnProfile && (
          <div className="pub-follow-wrap">
            <button
              className={`pub-follow-btn ${following ? 'pub-follow-btn--following' : ''}`}
              onClick={handleFollow}
              disabled={followLoading}
            >
              {followLoading ? '...' : following ? 'Following ✓' : '+ Follow'}
            </button>
            {followMsg && <p className="pub-follow-msg">{followMsg}</p>}
          </div>
        )}
      </div>

      {user.profileVisibility === 'private' ? (
        <div className="profile-card">
          <p className="profile-private-msg">This profile is private.</p>
        </div>
      ) : (
        <>
          <div className="profile-card">
            <div className="profile-info-row">
              <span className="profile-info-label">Username</span>
              <span className="profile-info-value">{user.username}</span>
            </div>
            {user.createdAt && (
              <div className="profile-info-row">
                <span className="profile-info-label">Joined</span>
                <span className="profile-info-value">
                  {new Date(user.createdAt).toLocaleDateString()}
                </span>
              </div>
            )}
          </div>

          {/* Their watchlist */}
          <div className="pub-watchlist-section">
            <h2 className="profile-section-heading">{user.username}'s Watchlist</h2>
            {watchlist.length === 0 ? (
              <p className="profile-search-hint">Nothing on their watchlist yet.</p>
            ) : (
              <ul className="pub-watchlist-list">
                {watchlist.map((item) => (
                  <li
                    key={item._id}
                    className="pub-watchlist-item"
                    onClick={() => navigate(`/media/${item.imdbID}`)}
                  >
                    {item.poster && item.poster.startsWith('http') ? (
                      <img src={item.poster} className="pub-wl-poster" alt={item.title || item.imdbID} />
                    ) : (
                      <div className="pub-wl-poster pub-wl-poster-ph" />
                    )}
                    <div className="pub-wl-info">
                      <p className="pub-wl-title">{item.title || item.imdbID}</p>
                      <p className="pub-wl-status">{statusLabel(item.status)}</p>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </>
      )}
    </div>
  );
};

export default UserPublicProfile;
