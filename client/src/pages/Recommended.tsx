import { useLocation, useNavigate } from 'react-router-dom';

const RecommendationsPage = () => {
  const { state } = useLocation();
  const navigate = useNavigate();
  const genres: string[] = state?.genres ?? [];

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
        <section key={genre}>
          <h2>{genre}</h2>
          {/* Fetch and render movies/shows for this genre */}
        </section>
      ))}
    </div>
  );
};

export default RecommendationsPage;