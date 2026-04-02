// GenreResults.tsx — /genre?type=movie&genre=Action
// Loads OMDb search results for a genre keyword + type, with a Load More button.

import React, { useState, useEffect, useContext } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { searchMedia, addToWatchlist, OmdbSearchResult } from '../api/mediaApi';
import { AuthContext } from '../context/AuthContext';
import MediaCard from '../components/MediaCard';
import '../styles/pages.css';

const GenreResults = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const context = useContext(AuthContext);
  const user = context?.user;

  const genre = searchParams.get('genre') || '';
  const type = searchParams.get('type') || 'movie'; // 'movie' | 'series'

  const [results, setResults] = useState<OmdbSearchResult[]>([]);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [error, setError] = useState('');

  const seenIds = React.useRef<Set<string>>(new Set());

  const fetchPage = async (pageNum: number, append = false) => {
    if (pageNum === 1) setLoading(true); else setLoadingMore(true);
    try {
      const mediaType = type === 'series' ? 'series' : 'movie';
      const res = await searchMedia(genre, mediaType, pageNum);
      // Filter out games, then deduplicate by imdbID
      const fresh = res.data.results.filter((item) => {
        if (item.type === 'game') return false;
        if (seenIds.current.has(item.imdbID)) return false;
        seenIds.current.add(item.imdbID);
        return true;
      });
      if (fresh.length === 0) setHasMore(false);
      setResults((prev) => (append ? [...prev, ...fresh] : fresh));
    } catch {
      if (!append) setError('Failed to load results.');
      setHasMore(false);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  useEffect(() => {
    if (genre) {
      seenIds.current = new Set();
      setResults([]);
      setPage(1);
      setHasMore(true);
      setError('');
      fetchPage(1, false);
    }
  }, [genre, type]);

  const handleLoadMore = () => {
    const next = page + 1;
    setPage(next);
    fetchPage(next, true);
  };

  const handleAddToWatchlist = async (imdbID: string): Promise<string> => {
    const found = results.find((r) => r.imdbID === imdbID);
    try {
      await addToWatchlist({
        imdbID,
        status: 'plan_to_watch',
        title: found?.title,
        poster: found?.poster,
      });
      return 'Added to watchlist!';
    } catch (err: any) {
      const msg = err.response?.data?.message || 'Failed to add';
      return msg === 'Item already in watchlist' ? 'Already in watchlist' : msg;
    }
  };

  return (
    <div className="page-wrapper genre-results">
      <button className="genre-back-btn" onClick={() => navigate(-1)}>← Back</button>
      <h1 className="page-heading">{genre} {type === 'movie' ? 'Films' : 'Shows'}</h1>

      {loading && <p className="genre-loading">Loading...</p>}
      {error && <p className="genre-error">{error}</p>}

      {!loading && results.length > 0 && (
        <>
          <div className="media-grid">
            {results.map((m) => (
              <MediaCard
                key={m.imdbID}
                media={m}
                onViewDetails={(id) => navigate(`/media/${id}`)}
                onAddToWatchlist={user ? handleAddToWatchlist : undefined}
              />
            ))}
          </div>

          {hasMore && (
            <div className="genre-load-more-wrap">
              <button
                className="genre-load-more-btn"
                onClick={handleLoadMore}
                disabled={loadingMore}
              >
                {loadingMore ? 'Loading...' : 'Load More'}
              </button>
            </div>
          )}
        </>
      )}

      {!loading && results.length === 0 && !error && (
        <p className="genre-empty">No results found for "{genre}".</p>
      )}
    </div>
  );
};

export default GenreResults;
