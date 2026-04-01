import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { searchMedia, OmdbSearchResult } from '../api/mediaApi';
import MediaCard from '../components/MediaCard';
import SearchBar from '../components/SearchBar';
import '../styles/search.css';

const Search = () => {
  const [results, setResults] = useState<OmdbSearchResult[]>([]);
  const [searched, setSearched] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

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
                  <MediaCard key={m.imdbID} media={m} onViewDetails={handleViewDetails} />
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
