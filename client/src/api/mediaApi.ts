// hsp - mediaApi.ts
// All API call functions for the WatchIt frontend.
// Changes from original:
//   - loginUser now sends username (not email) to match updated backend
//   - Added PublicUser interface
//   - Added searchUsers(query) for user search feature
//   - Added getPublicUser(userId) for public profile view

import apiClient from './apiClient';

export interface LoginPayload {
  username: string;
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
  title?: string;
  poster?: string;
}

export interface FeedItem {
  _id: string;
  username: string;
  imdbID: string;
  title: string;
  poster: string | null;
  status: string;
  dateAdded: string;
}

export interface ReviewAuthor {
  _id: string;
  username: string;
}

export interface Review {
  _id: string;
  userId: ReviewAuthor | string;
  imdbID: string;
  reviewText: string;
  rating?: number;
  createdAt: string;
}

export interface ReviewComment {
  _id: string;
  reviewId: string;
  authorUserId: ReviewAuthor | string;
  commentText: string;
  createdAt: string;
}

export interface UserProfile {
  _id: string;
  username: string;
  email: string;
  profileVisibility: string;
  createdAt: string;
}

// Public user view — safe fields only, no email or passwordHash
export interface PublicUser {
  _id: string;
  username: string;
  profileVisibility: string;
  createdAt?: string;
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

// ── Auth ─────────────────────────────────────────
export const registerUser = (username: string, email: string, password: string) => {
  return apiClient.post<AuthResponse>('auth/register', { username, email, password });
};

// Login now sends username (not email) — matches updated backend
export const loginUser = (username: string, password: string) => {
  return apiClient.post<AuthResponse>('auth/login', { username, password });
};

export const getProfile = () => {
  return apiClient.get<UserProfile>('auth/profile');
};

export const updateProfile = (data: { profileVisibility: string }) => {
  return apiClient.patch<{ message: string; user: UserProfile }>('auth/profile', data);
};

// ── User search ───────────────────────────────────
// Returns only safe public fields (_id, username, profileVisibility)
export const searchUsers = (query: string) => {
  return apiClient.get<{ users: PublicUser[] }>(
    `users/search?query=${encodeURIComponent(query)}`
  );
};

// Get a single public user profile by userId
export const getPublicUser = (userId: string) => {
  return apiClient.get<PublicUser>(`users/${userId}`);
};

// ── Media ─────────────────────────────────────────
export const searchMedia = (title: string, type?: 'movie' | 'series', page?: number) => {
  const typeParam = type ? `&type=${type}` : '';
  const pageParam = page && page > 1 ? `&page=${page}` : '';
  return apiClient.get<{ results: OmdbSearchResult[] }>(
    `media/search?title=${encodeURIComponent(title)}${typeParam}${pageParam}`
  );
};

export const getMediaByImdbID = (imdbID: string) => {
  return apiClient.get<Media>(`media/${imdbID}`);
};

// ── Watchlist ─────────────────────────────────────
export const getWatchlist = (userId: string) => {
  return apiClient.get<WatchlistItem[]>(`watchlist/${userId}`);
};

export const addToWatchlist = (data: { imdbID: string; status?: string; userRating?: number; title?: string; poster?: string }) => {
  return apiClient.post<WatchlistItem>('watchlist', data);
};

export const updateWatchlistItem = (id: string, data: { status?: string; userRating?: number }) => {
  return apiClient.put<WatchlistItem>(`watchlist/${id}`, data);
};

export const deleteWatchlistItem = (id: string) => {
  return apiClient.delete(`watchlist/${id}`);
};

// ── Reviews ───────────────────────────────────────
export const getReviews = (imdbID: string) => {
  return apiClient.get<Review[]>(`reviews/${imdbID}`);
};

export const addReview = (data: AddReviewPayload) => {
  return apiClient.post<{ message: string; data: Review }>('reviews', data);
};

// ── Review Comments ───────────────────────────────
export const getReviewComments = (reviewId: string) => {
  return apiClient.get<ReviewComment[]>(`review-comments/${reviewId}`);
};

export const addReviewComment = (data: AddReviewCommentPayload) => {
  return apiClient.post<{ message: string; data: ReviewComment }>('review-comments', data);
};

// ── Community Feed ────────────────────────────────
export const getFeed = () => {
  return apiClient.get<FeedItem[]>('feed');
};

// ── Friends / following ───────────────────────────
export interface FriendUser {
  _id: string;
  username: string;
  profileVisibility: string;
}

export const getFriends = () => {
  return apiClient.get<FriendUser[]>('friends');
};

export const followUser = (friendId: string) => {
  return apiClient.post(`friends/${friendId}`);
};

export const unfollowUser = (friendId: string) => {
  return apiClient.delete(`friends/${friendId}`);
};

export const checkFollowing = (friendId: string) => {
  return apiClient.get<{ following: boolean }>(`friends/check/${friendId}`);
};
