// hsp - Shows.tsx  (route: /shows)
// Matches the /shows mockup — identical layout to /films but:
//   - Heading is "Shows"
//   - Cards show year text subtly on the right (mockup shows "2025" beside label)
//   - Same 4-column grid + footer

import { useNavigate } from 'react-router-dom';
import '../styles/pages.css';

// Show genre cards with year and gradient art matching mockup colour swatches
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

const Shows = () => {
  const navigate = useNavigate();
  return (
    <div className="page-wrapper">
      {/* Page heading */}
      <h1 className="page-heading">Shows</h1>

      {/* 2-column genre card grid */}
      <div className="genre-grid">
        {SHOW_GENRES.map((genre) => (
          <div
            key={genre.label}
            className="genre-card"
            onClick={() => navigate(`/genre?type=series&genre=${encodeURIComponent(genre.label)}`)}
          >
            {/* Art tile */}
            <div
              className="genre-card-art"
              style={{ background: genre.gradient }}
            />
            {/* Label row */}
            <p className="genre-card-label">{genre.label}</p>
          </div>
        ))}
      </div>

      {/* Footer matching mockup */}
      <footer className="page-footer">
        <div>
          <h4>About WatchIt!</h4>
          <p>This was made for the CDP4331 (POGSD) large project.</p>
        </div>
        <div>
          <h4>Reach out</h4>
          <a href="#">Email</a>
          <a href="#">Instagram</a>
          <a href="#">LinkedIn</a>
        </div>
      </footer>
    </div>
  );
};

export default Shows;
