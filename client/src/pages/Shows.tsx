import { useState, useEffect, useRef, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import { searchMedia, addToWatchlist, OmdbSearchResult } from '../api/mediaApi';
import { AuthContext } from '../context/AuthContext';
import MediaCard from '../components/MediaCard';
import '../styles/pages.css';

const SHOW_GENRES = [
  { label: 'Action',      gradient: 'linear-gradient(135deg, #93cfef 0%, #d4f0c4 40%, #fce38a 100%)' },
  { label: 'Comedy',      gradient: 'linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%)' },
  { label: 'Drama',       gradient: 'linear-gradient(135deg, #a1c4fd 0%, #c2e9fb 100%)' },
  { label: 'Sci-Fi',      gradient: 'linear-gradient(135deg, #c3cfe2 0%, #c5b4e3 40%, #f0c27f 100%)' },
  { label: 'Romance',     gradient: 'linear-gradient(135deg, #a8edea 0%, #fed6e3 50%, #f8d97d 100%)' },
  { label: 'Documentary', gradient: 'radial-gradient(circle at 60% 50%, #26d0ce 20%, #c8f7c5 70%, #d0f0e0 100%)' },
  { label: 'Thriller',    gradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' },
  { label: 'Horror',      gradient: 'linear-gradient(135deg, #434343 0%, #471c1c 100%)' },
  { label: 'Animation',   gradient: 'linear-gradient(135deg, #93cfef 0%, #d4f0c4 40%, #fce38a 100%)' },
  { label: 'Crime',       gradient: 'linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%)' },
  { label: 'Fantasy',     gradient: 'linear-gradient(135deg, #a1c4fd 0%, #c2e9fb 100%)' },
  { label: 'Superhero',   gradient: 'linear-gradient(135deg, #c3cfe2 0%, #c5b4e3 40%, #f0c27f 100%)' },
];

// One row for a single genre
const GenreRow = ({
  genre,
  onAddToWatchlist,
}: {
  genre: string;
  onAddToWatchlist?: (id: string) => Promise<string>;
}) => {
  const navigate = useNavigate();
  const [results, setResults] = useState<OmdbSearchResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const seenIds = useRef<Set<string>>(new Set());

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const res = await searchMedia(genre, 'series', 1);
        const fresh = res.data.results.filter((item: OmdbSearchResult) => {
          if (item.type === 'game') return false;
          if (seenIds.current.has(item.imdbID)) return false;
          seenIds.current.add(item.imdbID);
          return true;
        });
        setResults(fresh);
      } catch {
        setError('Failed to load.');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [genre]);

  return (
    <section className="genre-row">
      {/* Row header */}
      <div className="genre-row-header">
        <h2 className="genre-row-title">{genre}</h2>
        <button
          className="genre-back-btn"
          onClick={() => navigate(`/genre?type=series&genre=${encodeURIComponent(genre)}`)}
        >
          More →
        </button>
      </div>

      {/* Scrollable card strip */}
      {loading && <p className="genre-loading">Loading...</p>}
      {error && <p className="genre-error">{error}</p>}
      {!loading && results.length > 0 && (
        <div className="genre-row-scroll">
          {results.map((m) => (
            <div className="genre-row-item" key={m.imdbID}>
              <MediaCard
                media={m}
                onViewDetails={(id) => navigate(`/media/${id}`)}
                onAddToWatchlist={onAddToWatchlist}
              />
            </div>
          ))}
        </div>
      )}
    </section>
  );
};

const Shows = () => {
  const navigate = useNavigate();
  const context = useContext(AuthContext);
  const user = context?.user;

  const handleAddToWatchlist = async (imdbID: string): Promise<string> => {
    try {
      await addToWatchlist({ imdbID, status: 'plan_to_watch' });
      return 'Added to watchlist!';
    } catch (err: any) {
      const msg = err.response?.data?.message || 'Failed to add';
      return msg === 'Item already in watchlist' ? 'Already in watchlist' : msg;
    }
  };

  return (
    <div className="shows-page page-wrapper">
      <h1 className="page-heading">Shows</h1>

      {SHOW_GENRES.map((genre) => (
        <GenreRow
          key={genre.label}
          genre={genre.label}
          onAddToWatchlist={user ? handleAddToWatchlist : undefined}
        />
      ))}

      <footer className="page-footer">
        <div>
          <h4>About WatchIt!</h4>
          <p>This was made for the COP4331 (POOSD) large project in Spring 2026.</p>
        </div>
      </footer>
    </div>
  );
};

export default Shows;