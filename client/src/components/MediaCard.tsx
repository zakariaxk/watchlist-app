import { useState } from 'react';
import '../styles/mediacard.css';
import { OmdbSearchResult } from '../api/mediaApi';

interface MediaCardProps {
  media: OmdbSearchResult;
  onViewDetails: (imdbID: string) => void;
  onAddToWatchlist?: (imdbID: string) => Promise<string>;
}

const MediaCard = ({ media, onViewDetails, onAddToWatchlist }: MediaCardProps) => {
  const [feedback, setFeedback] = useState('');
  const [adding, setAdding] = useState(false);

  const handleAdd = async () => {
    if (!onAddToWatchlist) return;
    setAdding(true);
    const msg = await onAddToWatchlist(media.imdbID);
    setFeedback(msg);
    setAdding(false);
    setTimeout(() => setFeedback(''), 3000);
  };

  return (
    <div className="media-card">
      <div className="media-poster">
        {media.poster && media.poster !== 'N/A' ? (
          <img src={media.poster} alt={media.title} />
        ) : (
          <div className="placeholder-poster">No Image</div>
        )}
      </div>
      <div className="media-info">
        <h3>{media.title}</h3>
        <p className="media-type">{media.type}</p>
        <p className="media-year">{media.year}</p>
        <div className="card-actions">
          <button onClick={() => onViewDetails(media.imdbID)} className="details-btn">
            View Details
          </button>
          {onAddToWatchlist && (
            <button onClick={handleAdd} disabled={adding} className="watchlist-btn">
              {adding ? '...' : '+ Watchlist'}
            </button>
          )}
        </div>
        {feedback && <p className="card-feedback">{feedback}</p>}
      </div>
    </div>
  );
};

export default MediaCard;
