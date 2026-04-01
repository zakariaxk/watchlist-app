import '../styles/mediacard.css';
import { OmdbSearchResult } from '../api/mediaApi';

interface MediaCardProps {
  media: OmdbSearchResult;
  onViewDetails: (imdbID: string) => void;
}

const MediaCard = ({ media, onViewDetails }: MediaCardProps) => {
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
        <button onClick={() => onViewDetails(media.imdbID)} className="details-btn">
          View Details
        </button>
      </div>
    </div>
  );
};

export default MediaCard;
