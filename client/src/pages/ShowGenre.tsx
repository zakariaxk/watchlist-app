// hsp - ShowGenre.tsx  (route: /show_genre)
// Genre browse page for shows. Matches the /show_genre mockup design language:
//   - Same navbar (handled globally)
//   - Clean white page with lots of whitespace
//   - Simple genre navigation grid using the same style as Films/Shows pages.

import { Link } from 'react-router-dom';
import '../styles/pages.css';

// Show genre tiles — minimal, clean, matching the same gradient art style
const GENRES = [
  { label: 'Action',      gradient: 'linear-gradient(135deg, #93cfef 0%, #d4f0c4 40%, #fce38a 100%)' },
  { label: 'Comedy',      gradient: 'linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%)' },
  { label: 'Drama',       gradient: 'linear-gradient(135deg, #a1c4fd 0%, #c2e9fb 100%)' },
  { label: 'Sci-Fi',      gradient: 'linear-gradient(135deg, #c3cfe2 0%, #c5b4e3 40%, #f0c27f 100%)' },
  { label: 'Romance',     gradient: 'linear-gradient(135deg, #a8edea 0%, #fed6e3 50%, #f8d97d 100%)' },
  { label: 'Documentary', gradient: 'radial-gradient(circle at 60% 50%, #26d0ce 20%, #c8f7c5 70%, #d0f0e0 100%)' },
  { label: 'Thriller',    gradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' },
  { label: 'Horror',      gradient: 'linear-gradient(135deg, #434343 0%, #000000 100%)' },
  { label: 'Animation',   gradient: 'linear-gradient(135deg, #93cfef 0%, #d4f0c4 40%, #fce38a 100%)' },
  { label: 'Crime',       gradient: 'linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%)' },
  { label: 'Fantasy',     gradient: 'linear-gradient(135deg, #a1c4fd 0%, #c2e9fb 100%)' },
  { label: 'Superhero',   gradient: 'linear-gradient(135deg, #c3cfe2 0%, #c5b4e3 40%, #f0c27f 100%)' },
];

const ShowGenre = () => {
  return (
    <div className="page-wrapper">
      {/* Page heading */}
      <h1 className="page-heading">Show Genres</h1>
      <p className="page-sub">Browse shows by genre</p>

      {/* 4-column genre grid — same component style as Films/Shows */}
      <div className="genre-grid">
        {GENRES.map((genre) => (
          // Each genre tile links to /shows?genre=... for future filtering
          <Link
            key={genre.label}
            to={`/shows?genre=${encodeURIComponent(genre.label)}`}
            className="genre-card genre-card-link"
            style={{ textDecoration: 'none' }}
          >
            <div
              className="genre-card-art"
              style={{ background: genre.gradient }}
            />
            <p className="genre-card-label">{genre.label}</p>
          </Link>
        ))}
      </div>

      {/* Footer matching other pages */}
      <footer className="page-footer">
        <div>
          <h4>About WatchIt!</h4>
          <p>This was made for the COP4331 (POOSD) large project.</p>
        </div>
      </footer>
    </div>
  );
};

export default ShowGenre;
