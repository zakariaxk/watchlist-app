import { useState, useEffect, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import '../styles/watchlist.css';

import { getMyWatchlist, updateWatchlistItem, deleteWatchlistItem } from '../api/mediaApi';
import { AuthContext } from '../context/AuthContext';

type WatchlistItem = {
  _id: string;
  imdbID: string;
  title?: string;
  poster?: string;
  status: string;
  userRating?: number;
};

const STATUS_OPTIONS = ['plan_to_watch', 'watching', 'completed'];

const STATUS_COLORS: Record<string, string> = {
  plan_to_watch: '#ffc107',
  watching: '#17a2b8',
  completed: '#28a745',
};

const hasUsablePoster = (poster?: string) => {
  if (!poster) return false;
  if (poster === 'N/A') return false;
  return /^https?:\/\//i.test(poster);
};

const getDisplayTitle = (item: WatchlistItem) => {
  const trimmedTitle = item.title?.trim();
  return trimmedTitle || item.imdbID || 'Unknown Title';
};

const getStarValue = (index: number, e: React.MouseEvent) => {
  const rect = (e.target as HTMLElement).getBoundingClientRect();
  const isHalf = e.clientX - rect.left < rect.width / 2;
  return index + (isHalf ? 0.5 : 1);
};

const Watchlist = () => {
  const [watchlistItems, setWatchlistItems] = useState<WatchlistItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [imageErrors, setImageErrors] = useState<Record<string, boolean>>({});
  const navigate = useNavigate();
  const context = useContext(AuthContext);
  const userId = context?.user?._id;

  
  useEffect(() => {
    const fetchWatchlist = async () => {
      try {
        setLoading(true);

        if (!userId) {
          setWatchlistItems([]);
          return;
        }

        const res = await getMyWatchlist();
        setWatchlistItems(res.data);
      } catch (err) {
        console.error('Failed to load watchlist:', err);
        setWatchlistItems([]);
      } finally {
        setLoading(false);
      }
    };

    fetchWatchlist();
  }, [userId]);


  const handleUpdate = async (
    id: string,
    field: 'status' | 'userRating',
    value: string | number
  ) => {
    try {
      await updateWatchlistItem(id, { [field]: value });

      setWatchlistItems((prev) =>
        prev.map((item) =>
          item._id === id ? { ...item, [field]: value } : item
        )
      );
    } catch (err) {
      console.error('Update failed:', err);
    }
  };

  const handleDelete = async (id: string) => {
    try {
      setDeletingId(id);
      await deleteWatchlistItem(id);
      setWatchlistItems((prev) => prev.filter((item) => item._id !== id));
      setImageErrors((prev) => {
        const next = { ...prev };
        delete next[id];
        return next;
      });
    } catch (err) {
      console.error('Delete failed:', err);
    } finally {
      setDeletingId(null);
    }
  };

 
  const renderStars = (rating: number, id: string) => {
    return (
      <div className="stars">
        {[0, 1, 2, 3, 4].map((i) => {
          const full = i + 1;
          const half = i + 0.5;

          return (
            <span
              key={i}
              className={`star ${
                rating >= full ? 'full' : rating >= half ? 'half' : ''
              }`}
              onClick={(e) =>
                handleUpdate(id, 'userRating', getStarValue(i, e))
              }
            >
              ★
            </span>
          );
        })}
      </div>
    );
  };


  if (loading) {
    return (
      <div className="watchlist-container">
        <h1>Watchlist</h1>
        <p>Loading...</p>
      </div>
    );
  }

  return (
    <div className="watchlist-container">
      <h1>Watchlist</h1>

      {watchlistItems.length === 0 ? (
        <div className="empty-state">
          <p>No items yet</p>
          <button className="browse-btn" onClick={() => navigate('/')}>
          Browse Movies
          </button>
          
        </div>
      ) : (
        <div className="watchlist-grid">
          {watchlistItems.map((item) => (
            <div key={item._id} className="watchlist-item">
              <h3>{getDisplayTitle(item)}</h3>

              {hasUsablePoster(item.poster) && !imageErrors[item._id] ? (
                <img
                  src={item.poster}
                  alt={getDisplayTitle(item)}
                  onError={() =>
                    setImageErrors((prev) => ({
                      ...prev,
                      [item._id]: true,
                    }))
                  }
                />
              ) : (
                <div className="watchlist-poster-placeholder">No Image</div>
              )}

              <select
                className="status-select"
                value={item.status}
                onChange={(e) =>
                  handleUpdate(item._id, 'status', e.target.value)
                }
                style={{
                  backgroundColor:
                    STATUS_COLORS[item.status] || '#ccc',
                }}
              >
                {STATUS_OPTIONS.map((s) => (
                  <option key={s} value={s}>
                    {s.replace('_', ' ')}
                  </option>
                ))}
              </select>

              <div className="rating-container">
                {renderStars(item.userRating || 0, item._id)}
                <span>{typeof item.userRating === 'number' ? item.userRating.toFixed(1) : 'No rating'}</span>
              </div>

              <button
                className="remove-btn"
                onClick={() => handleDelete(item._id)}
                disabled={deletingId === item._id}
              >
                {deletingId === item._id ? 'Removing...' : 'Remove'}
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Watchlist;
