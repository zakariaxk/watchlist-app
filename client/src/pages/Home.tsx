import { useNavigate } from 'react-router-dom';
import '../styles/home.css';

const Home = () => {
  const navigate = useNavigate();

  return (
    <div className="home-container">
      <h1>Discover Media</h1>
      <p>Search for movies and TV shows to add to your watchlist.</p>
      <button className="action-btn" onClick={() => navigate('/search')}>
        Search Media
      </button>
    </div>
  );
};

export default Home;
