import { useState, useContext } from 'react';
import { useNavigate } from 'react-router-dom';
import { searchMedia, addToWatchlist, OmdbSearchResult } from '../api/mediaApi';
import { AuthContext } from '../context/AuthContext';
import MediaCard from '../components/MediaCard';
import SearchBar from '../components/SearchBar';
import '../styles/search.css';

const Search = () => {
  const [results, setResults] = useState<OmdbSearchResult[]>([]);
  const [searched, setSearched] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const context = useContext(AuthContext);
  const user = context?.user;

  const handleSearch = async (query: string) => {
    if (!query.trim()) {
      setResults([]);
      setSearched(false);
      setError('');
      return;
    }

    setLoading(true);
    setSearched(true);
    setError('');

    try {
      const response = await searchMedia(query);
      setResults(response.data.results);
    } catch (err: unknown) {
      const axiosError = err as any;
      setError(axiosError.response?.data?.message || 'Search failed');
      setResults([]);
    } finally {
      setLoading(false);
    }
  };

  const handleViewDetails = (imdbID: string) => {
    navigate(`/media/${imdbID}`);
  };

  const handleAddToWatchlist = async (imdbID: string): Promise<string> => {
    try {
      await addToWatchlist({ imdbID, status: 'plan_to_watch' });
      return 'Added to watchlist!';
    } catch (err: unknown) {
      const axiosError = err as any;
      const msg = axiosError.response?.data?.message || 'Failed to add';
      if (msg === 'Item already in watchlist') return 'Already in watchlist';
      return msg;
    }
  };

  return (
    <div className="search-container">
      <h1>Search Media</h1>
      <SearchBar onSearch={handleSearch} />

      {loading && <div className="loading">Searching...</div>}
      {error && <div className="error-message">{error}</div>}

      {searched && !loading && !error && (
        <>
          {results.length === 0 ? (
            <div className="empty-state">
              <p>No results found</p>
            </div>
          ) : (
            <>
              <p className="results-count">Found {results.length} result(s)</p>
              <div className="media-grid">
                {results.map((m) => (
                  <MediaCard
                    key={m.imdbID}
                    media={m}
                    onViewDetails={handleViewDetails}
                    onAddToWatchlist={user ? handleAddToWatchlist : undefined}
                  />
                ))}
              </div>
            </>
          )}
        </>
      )}
    </div>
  );
};

export default Search;
