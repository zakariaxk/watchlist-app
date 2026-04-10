import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { getFeed, FeedItem } from '../api/mediaApi';
import logo from '../assets/images/watchit_mainlogo.png';
import '../styles/home.css';

const statusLabel = (s: string) => {
  if (s === 'plan_to_watch') return 'plans to watch';
  if (s === 'watching') return 'is now watching';
  if (s === 'completed') return 'finished watching';
  return s;
};

const Home = () => {
  const navigate = useNavigate();
  const [feed, setFeed] = useState<FeedItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getFeed()
      .then((res) => setFeed(res.data))
      .catch(() => setFeed([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="home-container">
      {/* Hero */}
      <div className="home-hero">
        <div className="main-logo">
          <img src={logo} alt="WatchIt" className = "fit-logo-image"/>
        </div>
        <h1>Discover Media</h1>
        <p>Search for movies and TV shows to add to your watchlist.</p>
        <button className="action-btn" onClick={() => navigate('/search')}>
          Search Media
        </button>
      </div>

      {/* Community feed */}
      <div className="home-feed">
        <h2 className="feed-heading">Community Activity</h2>
        {loading ? (
          <p className="feed-empty">Loading activity...</p>
        ) : feed.length === 0 ? (
          <p className="feed-empty">No public activity yet. Be the first to add something!</p>
        ) : (
          <div className="feed-list">
            {feed.map((item) => (
              <div
                key={item._id}
                className="feed-item"
                onClick={() => navigate(`/media/${item.imdbID}`)}
              >
                {item.poster && item.poster.startsWith('http') ? (
                  <img
                    src={item.poster}
                    className="feed-poster"
                    alt={item.title}
                  />
                ) : (
                  <div className="feed-poster feed-poster-ph" />
                )}
                <div className="feed-info">
                  <p className="feed-desc">
                    <span className="feed-user">@{item.username}</span>
                    {' '}{statusLabel(item.status)}{' '}
                    <span className="feed-media-title">{item.title}</span>
                  </p>
                  <p className="feed-date">
                    {new Date(item.dateAdded).toLocaleDateString()}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Home;

