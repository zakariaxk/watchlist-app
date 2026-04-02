// hsp - Search.tsx  (route: /search)
// Full search results page.
// Reads ?q= from URL so the navbar search bar can navigate here with a query.
// SearchBar requires ≥3 chars and debounces — already implemented in SearchBar.tsx.

import { useState, useContext, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
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
  const [searchParams] = useSearchParams();

  // On mount, run search if ?q= is present (navigated from navbar search)
  useEffect(() => {
    const q = searchParams.get('q');
    if (q && q.trim().length >= 3) {
      handleSearch(q.trim());
    }
  }, []);

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
    const found = results.find((r) => r.imdbID === imdbID);
    try {
      await addToWatchlist({ imdbID, status: 'plan_to_watch', title: found?.title, poster: found?.poster });
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
      <h1>Search</h1>
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
              <p className="results-count">{results.length} result{results.length !== 1 ? 's' : ''}</p>
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
