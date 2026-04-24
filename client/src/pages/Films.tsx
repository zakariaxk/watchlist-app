import { useState, useEffect, useRef, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import { searchMedia, addToWatchlist, OmdbSearchResult } from '../api/mediaApi';
import { AuthContext } from '../context/AuthContext';
import MediaCard from '../components/MediaCard';
import '../styles/pages.css';

const FILM_GENRES = [
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

const MOVIE_GENRE_SEEDS: Record<string, string[]> = {
  Action:      ['Mad Max Fury Road', 'John Wick', 'The Dark Knight', 'Die Hard', 'Gladiator'],
  Comedy:      ['Superbad', 'The Grand Budapest Hotel', 'Bridesmaids', 'Step Brothers', 'The Nice Guys'],
  Drama:       ['The Shawshank Redemption', 'Schindlers List', 'The Godfather', 'Moonlight', 'Parasite'],
  'Sci-Fi':    ['Interstellar', 'Inception', 'The Matrix', 'Arrival', 'Blade Runner 2049'],
  Romance:     ['La La Land', 'About Time', 'The Notebook', 'Before Sunrise', 'Pride and Prejudice'],
  Documentary: ['Free Solo', '13th', 'Amy', 'Searching for Sugar Man', 'Jiro Dreams of Sushi'],
  Thriller:    ['Gone Girl', 'Prisoners', 'Zodiac', 'Se7en', 'Sicario'],
  Horror:      ['Hereditary', 'Get Out', 'The Witch', 'Midsommar', 'A Quiet Place'],
  Animation:   ['Spider-Man Into the Spider-Verse', 'Spirited Away', 'WALL-E', 'Coco', 'Toy Story'],
  Crime:       ['The Godfather', 'Goodfellas', 'The Departed', 'Zodiac', 'Heat'],
  Fantasy:     ['The Lord of the Rings', 'Pan Labyrinth', 'The Princess Bride', 'Big Fish', 'Stardust'],
  Superhero:   ['The Dark Knight', 'Spider-Man Into the Spider-Verse', 'Logan', 'Avengers Endgame', 'The Incredibles'],
};

const CACHE_TTL_MS = 1000 * 60 * 60 * 6; // 6 hours

const getCached = (key: string): OmdbSearchResult[] | null => {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return null;
    const { timestamp, data } = JSON.parse(raw);
    if (Date.now() - timestamp > CACHE_TTL_MS) {
      localStorage.removeItem(key);
      return null;
    }
    return data;
  } catch {
    return null;
  }
};

const setCached = (key: string, data: OmdbSearchResult[]) => {
  try {
    localStorage.setItem(key, JSON.stringify({ timestamp: Date.now(), data }));
  } catch {
    // localStorage full or unavailable — fail silently
  }
};

const sleep = (ms: number) => new Promise((res) => setTimeout(res, ms));
// One row for a single genre
const GenreRow = ({
  genre,
  onAddToWatchlist,
}: {
  genre: string;
  onAddToWatchlist?: (
    id: string,
    mediaMeta?: { title?: string; poster?: string }
  ) => Promise<string>;
}) => {
  const navigate = useNavigate();
  const [results, setResults] = useState<OmdbSearchResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const seenIds = useRef<Set<string>>(new Set());

  useEffect(() => {
  const load = async () => {
    setLoading(true);
    seenIds.current.clear();

    const cacheKey = `watchit_movies_${genre}`; // use watchit_shows_ in Shows.tsx
    const cached = getCached(cacheKey);
    if (cached) {
      setResults(cached);
      setLoading(false);
      return; // skip all requests
    }

    try {
      const seeds = MOVIE_GENRE_SEEDS[genre] ?? [];
      const fresh: OmdbSearchResult[] = [];

      for (let i = 0; i < seeds.length; i++) {
        await sleep(200);
        try {
          const res = await fetchWithRetry(seeds[i], 'movie');
          if (!res) continue;
          for (const item of res.data.results) {
            if (item.type === 'game') continue;
            if (item.type === 'series') continue;
            if (seenIds.current.has(item.imdbID)) continue;
            seenIds.current.add(item.imdbID);
            fresh.push(item);
            break;
          }
          setResults([...fresh]);
        } catch {
          continue;
        }
      }

      setCached(cacheKey, fresh); // save to cache after all fetches complete
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
          onClick={() => navigate(`/genre?type=movie&genre=${encodeURIComponent(genre)}`)}
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

const Films = () => {
  const navigate = useNavigate();
  const context = useContext(AuthContext);
  const user = context?.user;

  const handleAddToWatchlist = async (
    imdbID: string,
    mediaMeta?: { title?: string; poster?: string }
  ): Promise<string> => {
    try {
      await addToWatchlist({
        imdbID,
        status: 'plan_to_watch',
        title: mediaMeta?.title,
        poster: mediaMeta?.poster,
      });
      return 'Added to watchlist!';
    } catch (err: any) {
      const msg = err.response?.data?.message || 'Failed to add';
      return msg === 'Item already in watchlist' ? 'Already in watchlist' : msg;
    }
  };

  return (
    <div className="shows-page page-wrapper">
      <h1 className="page-heading">Movies</h1>

      {FILM_GENRES.map((genre) => (
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

export default Films;