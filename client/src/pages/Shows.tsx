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

const SHOW_GENRE_SEEDS: Record<string, string[]> = {
  Action:      ['24', 'Reacher', 'Jack Ryan', 'Strike Back', 'The Boys', 'Narcos', 'Prison Break', 'Alias', 'Burn Notice', 'Chuck'],
  Comedy:      ['Seinfeld', 'The Office', 'Parks and Recreation', 'Arrested Development', 'Brooklyn Nine-Nine', 'Schitts Creek', 'Its Always Sunny', 'Frasier', 'Curb Your Enthusiasm', 'What We Do in the Shadows'],
  Drama:       ['The Wire', 'Succession', 'Ozark', 'The Crown', 'Yellowstone', 'Mindhunter', 'Mare of Easttown', 'Severance', 'Better Call Saul', 'The Americans'],
  'Sci-Fi':    ['Westworld', 'Dark', 'Black Mirror', 'The Expanse', 'Fringe', 'Altered Carbon', 'Orphan Black', 'Battlestar Galactica', 'Devs', 'Severance'],
  Romance:     ['Bridgerton', 'Normal People', 'Virgin River', 'Emily in Paris', 'Outlander', 'Jane the Virgin', 'Fleabag', 'Sweet Magnolias', 'Ginny and Georgia', 'One Day'],
  Documentary: ['Making a Murderer', 'The Last Dance', 'Wild Wild Country', 'Tiger King', 'The Jinx', 'Chefs Table', 'Icarus', 'Allen v Farrow', 'The Vow', 'Formula 1: Drive to Survive'],
  Thriller:    ['Mindhunter', 'Killing Eve', 'Hannibal', 'The Sinner', 'Sharp Objects', 'You', 'Bloodline', 'Ozark', 'The Fall', 'Luther'],
  Horror:      ['The Haunting of Hill House', 'Stranger Things', 'American Horror Story', 'The Walking Dead', 'Midnight Mass', 'Ratched', 'Channel Zero', 'Marianne', 'The Terror', 'Debris'],
  Animation:   ['Arcane', 'Avatar The Last Airbender', 'BoJack Horseman', 'Rick and Morty', 'Gravity Falls', 'Castlevania', 'Invincible', 'Over the Garden Wall', 'Primal', 'The Legend of Korra'],
  Crime:       ['The Wire', 'True Detective', 'Fargo', 'Narcos', 'Peaky Blinders', 'The Sopranos', 'Mindhunter', 'The Shield', 'Ozark', 'Sneaky Pete'],
  Fantasy:     ['Game of Thrones', 'The Witcher', 'House of the Dragon', 'Shadow and Bone', 'The Wheel of Time', 'Merlin', 'His Dark Materials', 'Carnival Row', 'Cursed', 'The Shannara Chronicles'],
  Superhero:   ['The Boys', 'Invincible', 'Daredevil', 'Loki', 'WandaVision', 'Peacemaker', 'The Umbrella Academy', 'Legion', 'Agents of Shield', 'Titans'],
};

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
    try {
      const seeds = SHOW_GENRE_SEEDS[genre] ?? [];
      const fresh: OmdbSearchResult[] = [];
      const BATCH_SIZE = 3;
      const DELAY_MS = 300;

      for (let i = 0; i < seeds.length; i += BATCH_SIZE) {
        const batch = seeds.slice(i, i + BATCH_SIZE);
        const responses = await Promise.allSettled(
          batch.map((title) => searchMedia(title, 'series', 1))
        );
        for (const r of responses) {
          if (r.status !== 'fulfilled') continue;
          for (const item of r.value.data.results) {
            if (item.type === 'game') continue;
            if (item.type === 'movie') continue;
            if (seenIds.current.has(item.imdbID)) continue;
            seenIds.current.add(item.imdbID);
            fresh.push(item);
            break;
          }
        }
        if (i + BATCH_SIZE < seeds.length) await sleep(DELAY_MS);
      }
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