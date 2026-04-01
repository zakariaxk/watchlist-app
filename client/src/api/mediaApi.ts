import apiClient from './apiClient';

export interface LoginPayload {
  email: string;
  password: string;
}

export interface RegisterPayload {
  username: string;
  email: string;
  password: string;
}

export interface AuthResponse {
  user: {
    _id: string;
    username: string;
    email: string;
  };
  token: string;
}

export interface Media {
  _id: string;
  imdbID: string;
  title: string;
  createdAt: string;
  year?: string;
  type?: string;
  genres?: string[];
  poster?: string;
  description?: string;
}

export interface OmdbSearchResult {
  imdbID: string;
  title: string;
  year: string;
  type: string;
  poster: string;
}

export interface WatchlistItem {
  _id: string;
  userId: string;
  imdbID: string;
  status: string;
  userRating?: number;
  dateAdded: string;
}

export interface Review {
  _id: string;
  userId: string;
  imdbID: string;
  reviewText: string;
  rating?: number;
  createdAt: string;
}

export interface ReviewComment {
  _id: string;
  reviewId: string;
  authorUserId: string;
  commentText: string;
  createdAt: string;
}

export interface AddReviewPayload {
  imdbID: string;
  reviewText: string;
  rating?: number;
}

export interface AddReviewCommentPayload {
  reviewId: string;
  commentText: string;
}

export const registerUser = (username: string, email: string, password: string) => {
  return apiClient.post<AuthResponse>('auth/register', { username, email, password });
};

export const loginUser = (email: string, password: string) => {
  return apiClient.post<AuthResponse>('auth/login', { email, password });
};

export const searchMedia = (title: string) => {
  return apiClient.get<{ results: OmdbSearchResult[] }>(`media/search?title=${encodeURIComponent(title)}`);\n};
};

export const getMediaByImdbID = (imdbID: string) => {
  return apiClient.get<Media>(`media/${imdbID}`);
};

export const getWatchlist = (userId: string) => {
  return apiClient.get<WatchlistItem[]>(`watchlist/${userId}`);
};

export const addToWatchlist = (data: { imdbID: string; status?: string; userRating?: number }) => {
  return apiClient.post<WatchlistItem>('watchlist', data);
};

export const updateWatchlistItem = (id: string, data: { status?: string; userRating?: number }) => {
  return apiClient.put<WatchlistItem>(`watchlist/${id}`, data);
};

export const deleteWatchlistItem = (id: string) => {
  return apiClient.delete(`watchlist/${id}`);
};

export const getReviews = (imdbID: string) => {
  return apiClient.get<Review[]>(`reviews/${imdbID}`);
};

export const addReview = (data: AddReviewPayload) => {
  return apiClient.post<Review>('reviews', data);
};

export const getReviewComments = (reviewId: string) => {
  return apiClient.get<ReviewComment[]>(`review-comments/${reviewId}`);
};

export const addReviewComment = (data: AddReviewCommentPayload) => {
  return apiClient.post<ReviewComment>('review-comments', data);
};
