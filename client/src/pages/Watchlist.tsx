import { useState, useEffect, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import { getWatchlist, WatchlistItem } from '../api/mediaApi';
import { AuthContext } from '../context/AuthContext';
import '../styles/watchlist.css';

const Watchlist = () => {
  const [watchlistItems, setWatchlistItems] = useState<WatchlistItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const context = useContext(AuthContext);
  const navigate = useNavigate();

  if (!context) {
    return <div>Loading...</div>;
  }

  const { user } = context;

  useEffect(() => {
    const fetchWatchlist = async () => {
      try {
        if (user?._id) {
          const response = await getWatchlist(user._id);
          setWatchlistItems(response.data);
        }
      } catch (err) {
        setError('Failed to load watchlist');
      } finally {
        setLoading(false);
      }
    };

    fetchWatchlist();
  }, [user]);

  if (loading) {
    return <div className="loading">Loading watchlist...</div>;
  }

  if (error) {
    return <div className="error-message">{error}</div>;
  }

  return (
    <div className="watchlist-container">
      <h1>My Watchlist</h1>
      {watchlistItems.length === 0 ? (
        <div className="empty-state">
          <p>No items in your watchlist yet</p>
          <button onClick={() => navigate('/')} className="action-btn">
            Browse Media
          </button>
        </div>
      ) : (
        <div className="watchlist-grid">
          {watchlistItems.map((item) => (
            <div key={item._id} className="watchlist-item">
              <h3>{item.imdbID}</h3>
              <p>Status: {item.status}</p>
              <p>Rating: {item.userRating ?? 'Not rated'}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Watchlist;
