import { useState, useEffect, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import { getWatchlist, updateWatchlistItem, WatchlistItem } from '../api/mediaApi';
import { AuthContext } from '../context/AuthContext';
import '../styles/watchlist.css';

const STATUS_OPTIONS = ['plan_to_watch', 'watching', 'completed'];

const STATUS_COLORS: Record<string, string> = {
  plan_to_watch: '#ffc107', // yellow
  watching: '#17a2b8',      // blue
  completed: '#28a745',     // green
};

const Watchlist = () => {
  const [watchlistItems, setWatchlistItems] = useState<WatchlistItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const context = useContext(AuthContext);
  const navigate = useNavigate();

  if (!context) return <div>Loading...</div>;
  const { user } = context;

  // Fetch watchlist from API
  useEffect(() => {
    const fetchWatchlist = async () => {
      try {
        if (user?._id) {
          const response = await getWatchlist(user._id);
          setWatchlistItems(response.data);
        }
      } catch {
        setError('Failed to load watchlist');
      } finally {
        setLoading(false);
      }
    };

    fetchWatchlist();
  }, [user]);

  // Handle status or rating update
  const handleUpdate = async (itemId: string, field: 'status' | 'userRating', value: string | number) => {
    try {
      await updateWatchlistItem(itemId, { [field]: value });
      setWatchlistItems((prev) =>
        prev.map((item) => (item._id === itemId ? { ...item, [field]: value } : item))
      );
    } catch {
      alert('Failed to update watchlist item');
    }
  };

  if (loading) return <div className="loading">Loading watchlist...</div>;
  if (error) return <div className="error-message">{error}</div>;

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
              <h3>{item.title ?? item.imdbID}</h3>
              {item.poster && item.poster !== 'N/A' && (
                <img src={item.poster} alt={item.title} style={{ maxWidth: 120, marginBottom: 8 }} />
              )}

              {/* STATUS DROPDOWN WITH BADGE STYLE */}
              <div className="status-container">
                <label>Status:</label>
                <select
                  value={item.status}
                  onChange={(e) => handleUpdate(item._id, 'status', e.target.value)}
                  className="status-dropdown-badge"
                  style={{ backgroundColor: STATUS_COLORS[item.status] }}
                >
                  {STATUS_OPTIONS.map((status) => (
                    <option key={status} value={status}>
                      {status.replace('_', ' ')}
                    </option>
                  ))}
                </select>
              </div>

              {/* RATING */}
              <div className="rating-container">
                <label>Rating:</label>
                <input
                  type="number"
                  min={1}
                  max={10}
                  value={item.userRating ?? ''}
                  onChange={(e) => handleUpdate(item._id, 'userRating', Number(e.target.value))}
                  placeholder="1–10"
                  className="rating-input"
                />
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Watchlist;