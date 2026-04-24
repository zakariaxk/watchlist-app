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
  Action:      ['Mad Max Fury Road', 'John Wick', 'The Dark Knight', 'Mission Impossible Fallout', 'Die Hard', 'Heat', 'Gladiator', 'Top Gun Maverick', 'The Raid', 'Atomic Blonde'],
  Comedy:      ['Superbad', 'The Grand Budapest Hotel', 'Bridesmaids', 'Game Night', 'Step Brothers', 'The Nice Guys', 'Knives Out', 'What We Do in the Shadows', 'Palm Springs', 'Ticket to Paradise'],
  Drama:       ['The Shawshank Redemption', 'Schindlers List', 'There Will Be Blood', 'No Country for Old Men', 'Moonlight', 'Marriage Story', 'Manchester by the Sea', 'The Godfather', 'Nomadland', 'Parasite'],
  'Sci-Fi':    ['Interstellar', 'Inception', 'The Matrix', 'Arrival', 'Blade Runner 2049', 'Ex Machina', 'Dune', 'Annihilation', 'Edge of Tomorrow', 'District 9'],
  Romance:     ['La La Land', 'About Time', 'Crazy Rich Asians', 'The Notebook', 'Before Sunrise', 'Eternal Sunshine of the Spotless Mind', 'Pride and Prejudice', 'Call Me By Your Name', 'Portrait of a Lady on Fire', 'Atonement'],
  Documentary: ['No Other Land', 'Free Solo', 'The Act of Killing', '13th', 'Amy', 'Searching for Sugar Man', 'I Am Not Your Negro', 'Jiro Dreams of Sushi', 'The Imposter', 'Honeyland'],
  Thriller:    ['Gone Girl', 'Prisoners', 'Zodiac', 'Se7en', 'Parasite', 'Nocturnal Animals', 'Knives Out', 'The Girl with the Dragon Tattoo', 'Sicario', 'Tinker Tailor Soldier Spy'],
  Horror:      ['Hereditary', 'Get Out', 'The Witch', 'Midsommar', 'A Quiet Place', 'It Follows', 'The Babadook', 'Us', 'Sinister', 'The Conjuring'],
  Animation:   ['Spider-Man Into the Spider-Verse', 'Spirited Away', 'The Lion King', 'WALL-E', 'Coco', 'Princess Mononoke', 'Toy Story', 'Howls Moving Castle', 'Klaus', 'Wolfwalkers'],
  Crime:       ['The Godfather', 'Goodfellas', 'Heat', 'No Country for Old Men', 'Prisoners', 'Zodiac', 'The Departed', 'Sicario', 'Blood Simple', 'Memories of Murder'],
  Fantasy:     ['The Lord of the Rings', 'Pan Labyrinth', 'Princess Mononoke', 'The Shape of Water', 'Stardust', 'Big Fish', 'The Princess Bride', 'Willow', 'Labyrinth', 'The NeverEnding Story'],
  Superhero:   ['The Dark Knight', 'Spider-Man Into the Spider-Verse', 'Logan', 'Avengers Endgame', 'Thor Ragnarok', 'Black Panther', 'Guardians of the Galaxy', 'The Incredibles', 'Unbreakable', 'Shazam'],
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
      const seeds = MOVIE_GENRE_SEEDS[genre] ?? [];
      const responses = await Promise.allSettled(
        seeds.map((title) => searchMedia(title, 'series', 1))
      );
      const fresh: OmdbSearchResult[] = [];
      for (const r of responses) {
        if (r.status !== 'fulfilled') continue;
        for (const item of r.value.data.results) {
          if (item.type === 'game') continue;
          if (seenIds.current.has(item.imdbID)) continue;
          seenIds.current.add(item.imdbID);
          fresh.push(item);
          break; // only take the first result per seed title
        }
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