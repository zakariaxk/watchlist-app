import { useState, useEffect, useContext, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { searchMedia, addToWatchlist, OmdbSearchResult } from '../api/mediaApi';
import { AuthContext } from '../context/AuthContext';
import MediaCard from '../components/MediaCard';

// Fetches and displays one genre's results
const GenreSection = ({
  genre,
  onAddToWatchlist,
  onViewDetails,
}: {
  genre: string;
  onAddToWatchlist?: (id: string) => Promise<string>;
  onViewDetails: (id: string) => void;
}) => {
  const [results, setResults] = useState<OmdbSearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const seenIds = useRef<Set<string>>(new Set());

  useEffect(() => {
    const fetch = async () => {
      setLoading(true);
      try {
        // Fetch both movies and series for each genre
        const [movies, series] = await Promise.all([
          searchMedia(genre, 'movie', 1),
          searchMedia(genre, 'series', 1),
        ]);

        const combined = [...movies.data.results, ...series.data.results].filter((item) => {
          if (item.type === 'game') return false;
          if (seenIds.current.has(item.imdbID)) return false;
          seenIds.current.add(item.imdbID);
          return true;
        });

        setResults(combined);
      } catch {
        setError(`Failed to load results for ${genre}.`);
      } finally {
        setLoading(false);
      }
    };

    fetch();
  }, [genre]);

  if (loading) return <p className="genre-loading">Loading {genre}...</p>;
  if (error) return <p className="genre-error">{error}</p>;
  if (results.length === 0) return null;

  return (
    <section key={genre} className="recommendations-genre-section">
      <h2>{genre}</h2>
      <div className="media-grid">
        {results.map((m) => (
          <MediaCard
            key={m.imdbID}
            media={m}
            onViewDetails={onViewDetails}
            onAddToWatchlist={onAddToWatchlist}
          />
        ))}
      </div>
    </section>
  );
};

const RecommendationsPage = () => {
    const { state } = useLocation();
    const navigate = useNavigate();
    const context = useContext(AuthContext);
    const user = context?.user;
    const genres: string[] = state?.genres ?? [];

    const handleAddToWatchlist = async (imdbID: string): Promise<string> => {
    try {
      await addToWatchlist({ imdbID, status: 'plan_to_watch' });
      return 'Added to watchlist!';
    } catch (err: any) {
      const msg = err.response?.data?.message || 'Failed to add';
      return msg === 'Item already in watchlist' ? 'Already in watchlist' : msg;
    }
  };

  if (genres.length === 0) {
    return (
      <div>
        <h1>Your Picks</h1>
        <p>No genres selected.</p>
        <button onClick={() => navigate('/signup')}>Go back</button>
      </div>
    );
  }

  return (
    <div className="recommendations-page">
      <h1>Your Picks</h1>
      <p>Showing recommendations for: {genres.join(', ')}</p>

      {/* Map over genres to render filtered sections */}
      {genres.map((genre) => (
        <GenreSection
          key={genre}
          genre={genre}
          onAddToWatchlist={handleAddToWatchlist}
          onViewDetails={(id) => navigate(`/details/${id}`)}
        />
      ))}
    </div>
  );
};

export default RecommendationsPage;