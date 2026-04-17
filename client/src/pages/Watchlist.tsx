import { useState, useEffect, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import '../styles/watchlist.css';

import { getMyWatchlist, updateWatchlistItem } from '../api/mediaApi';
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

const getStarValue = (index: number, e: React.MouseEvent) => {
  const rect = (e.target as HTMLElement).getBoundingClientRect();
  const isHalf = e.clientX - rect.left < rect.width / 2;
  return index + (isHalf ? 0.5 : 1);
};

const Watchlist = () => {
  const [watchlistItems, setWatchlistItems] = useState<WatchlistItem[]>([]);
  const [loading, setLoading] = useState(true);
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
              <h3>{item.title}</h3>

              {/* POSTER (assumed already stored in DB) */}
              {item.poster && (
                <img src={item.poster} alt={item.title} />
              )}

              {/* STATUS */}
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

              {/* RATING */}
              <div className="rating-container">
                {renderStars(item.userRating || 0, item._id)}
                <span>{item.userRating?.toFixed(1)}</span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Watchlist;