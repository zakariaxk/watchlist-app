// hsp - MediaDetail.tsx  (route: /media/:imdbID)
// Fixes applied:
//   1. Poster constrained to max 200px wide — no longer oversized
//   2. Fallback placeholder shown when poster is missing/N/A
//   3. Comments append immediately after posting (no blank-out bug)
//   4. Usernames shown for reviews and comments (not raw IDs)
//   5. Watchlist duplicate handled gracefully

import { useState, useEffect, useContext } from 'react';
import { useParams } from 'react-router-dom';
import {
  getMediaByImdbID,
  getReviews,
  addReview,
  addToWatchlist,
  getReviewComments,
  addReviewComment,
  Media,
  Review,
  ReviewComment,
  ReviewAuthor,
} from '../api/mediaApi';
import { AuthContext } from '../context/AuthContext';
import '../styles/mediadetail.css';

const getUsername = (userId: ReviewAuthor | string): string => {
  if (typeof userId === 'object' && userId !== null) return userId.username;
  return 'User';
};

interface ReviewWithComments extends Review {
  commentsOpen: boolean;
  comments: ReviewComment[];
  commentsLoading: boolean;
  newComment: string;
}

const MediaDetail = () => {
  const { id } = useParams<{ id: string }>();
  const [media, setMedia] = useState<Media | null>(null);
  const [reviews, setReviews] = useState<ReviewWithComments[]>([]);
  const [newReviewText, setNewReviewText] = useState('');
  const [newReviewRating, setNewReviewRating] = useState('');
  const [reviewError, setReviewError] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [watchlistMsg, setWatchlistMsg] = useState('');
  const context = useContext(AuthContext);

  if (!context) {
    return <div>Loading...</div>;
  }

  const { user } = context;

  useEffect(() => {
    const fetchData = async () => {
      if (!id) return;
      try {
        const mediaResponse = await getMediaByImdbID(id);
        setMedia(mediaResponse.data);

        const reviewsResponse = await getReviews(id);
        setReviews(
          reviewsResponse.data.map((r) => ({
            ...r,
            commentsOpen: false,
            comments: [],
            commentsLoading: false,
            newComment: '',
          }))
        );
      } catch (err: unknown) {
        const axiosError = err as any;
        setError(axiosError.response?.data?.message || 'Failed to load media details');
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [id]);

  const handleAddToWatchlist = async () => {
    if (!id) return;
    try {
      await addToWatchlist({
        imdbID: id,
        status: 'plan_to_watch',
        title: media?.title,
        poster: media?.poster,
      });
      setWatchlistMsg('Added to watchlist!');
    } catch (err: unknown) {
      const axiosError = err as any;
      const msg = axiosError.response?.data?.message || 'Failed to add';
      setWatchlistMsg(msg === 'Item already in watchlist' ? 'Already in your watchlist' : msg);
    }
    setTimeout(() => setWatchlistMsg(''), 3000);
  };

  const handleAddReview = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!newReviewText.trim() || !user || !id) return;
    setReviewError('');
    try {
      const response = await addReview({
        imdbID: id,
        reviewText: newReviewText,
        rating: newReviewRating ? Number(newReviewRating) : undefined,
      });
      // response.data is { message, data: Review }
      const saved = response.data.data;
      setReviews((prev) => [
        ...prev,
        { ...saved, commentsOpen: false, comments: [], commentsLoading: false, newComment: '' },
      ]);
      setNewReviewText('');
      setNewReviewRating('');
    } catch (err) {
      setReviewError('Failed to add review');
    }
  };

  const toggleComments = async (reviewId: string) => {
    setReviews((prev) =>
      prev.map((r) => {
        if (r._id !== reviewId) return r;
        const opening = !r.commentsOpen;
        if (opening && r.comments.length === 0) {
          // fetch comments
          loadComments(reviewId);
        }
        return { ...r, commentsOpen: opening };
      })
    );
  };

  const loadComments = async (reviewId: string) => {
    setReviews((prev) =>
      prev.map((r) => (r._id === reviewId ? { ...r, commentsLoading: true } : r))
    );
    try {
      const res = await getReviewComments(reviewId);
      setReviews((prev) =>
        prev.map((r) =>
          r._id === reviewId ? { ...r, comments: res.data, commentsLoading: false } : r
        )
      );
    } catch {
      setReviews((prev) =>
        prev.map((r) => (r._id === reviewId ? { ...r, commentsLoading: false } : r))
      );
    }
  };

  const handleCommentChange = (reviewId: string, value: string) => {
    setReviews((prev) =>
      prev.map((r) => (r._id === reviewId ? { ...r, newComment: value } : r))
    );
  };

  const handleAddComment = async (e: React.FormEvent, reviewId: string) => {
    e.preventDefault();
    const review = reviews.find((r) => r._id === reviewId);
    if (!review?.newComment.trim() || !user) return;
    try {
      const res = await addReviewComment({ reviewId, commentText: review.newComment });
      const saved = res.data.data;
      setReviews((prev) =>
        prev.map((r) =>
          r._id === reviewId
            ? { ...r, comments: [...r.comments, saved], newComment: '' }
            : r
        )
      );
    } catch {
      // silent — could add per-review error if needed
    }
  };

  if (loading) return <div className="loading">Loading...</div>;
  if (error) return <div className="error-message">{error}</div>;
  if (!media) return <div className="error-message">Media not found</div>;

  return (
    <div className="media-detail-container">
      <div className="media-detail-header">
        {/* Poster — constrained width, aspect ratio preserved, fallback placeholder */}
        <div className="media-poster-wrap">
          {media.poster && media.poster !== 'N/A' && media.poster !== '' ? (
            <img
              src={media.poster}
              alt={media.title}
              className="media-poster-img"
            />
          ) : (
            <div className="media-poster-placeholder">No Image</div>
          )}
        </div>

        <div className="media-details">
          <h1>{media.title}</h1>
          <p className="media-type">{media.type}</p>
          <p className="media-year">{media.year}</p>
          <p className="media-genres">{media.genres?.join(', ')}</p>
          <p className="media-description">{media.description}</p>
          {user && (
            <div className="watchlist-action">
              <button onClick={handleAddToWatchlist} className="add-watchlist-btn">
                + Add to Watchlist
              </button>
              {watchlistMsg && <span className="watchlist-feedback">{watchlistMsg}</span>}
            </div>
          )}
        </div>
      </div>

      <div className="comments-section">
        <h2>Reviews</h2>
        {user && (
          <form onSubmit={handleAddReview} className="comment-form">
            <textarea
              value={newReviewText}
              onChange={(e) => setNewReviewText(e.target.value)}
              placeholder="Write a review..."
              required
            />
            <div className="review-form-row">
              <input
                type="number"
                min="1"
                max="10"
                value={newReviewRating}
                onChange={(e) => setNewReviewRating(e.target.value)}
                placeholder="Rating 1–10 (optional)"
                className="rating-input"
              />
              <button type="submit" className="submit-review-btn">
                Submit Review
              </button>
            </div>
            {reviewError && <p className="error-message">{reviewError}</p>}
          </form>
        )}

        {reviews.length === 0 ? (
          <p className="no-reviews-msg">No reviews yet. Be the first!</p>
        ) : (
          <div className="comments-list">
            {reviews.map((review) => (
              <div key={review._id} className="comment">
                <p className="comment-author">{getUsername(review.userId)}</p>
                <p className="comment-text">{review.reviewText}</p>
                {review.rating && (
                  <p className="comment-rating">Rating: {review.rating}/10</p>
                )}
                <button
                  className="toggle-comments-btn"
                  onClick={() => toggleComments(review._id)}
                >
                  {review.commentsOpen ? 'Hide Comments' : 'Comments'}
                </button>

                {review.commentsOpen && (
                  <div className="review-comments">
                    {review.commentsLoading && <p className="loading-small">Loading...</p>}
                    {review.comments.map((c) => (
                      <div key={c._id} className="review-comment">
                        <span className="rc-author">{getUsername(c.authorUserId)}</span>
                        <span className="rc-text">{c.commentText}</span>
                      </div>
                    ))}
                    {user && (
                      <form
                        className="inline-comment-form"
                        onSubmit={(e) => handleAddComment(e, review._id)}
                      >
                        <input
                          type="text"
                          value={review.newComment}
                          onChange={(e) => handleCommentChange(review._id, e.target.value)}
                          placeholder="Add a comment..."
                          required
                        />
                        <button type="submit">Post</button>
                      </form>
                    )}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default MediaDetail;
