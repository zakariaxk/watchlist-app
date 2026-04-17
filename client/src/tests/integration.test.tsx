import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { cleanup, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import Search from '../pages/Search';
import { AuthContext, AuthContextType, User } from '../context/AuthContext';
import { addToWatchlist, searchMedia } from '../api/mediaApi';

vi.mock('../api/mediaApi', () => ({
  searchMedia: vi.fn(),
  addToWatchlist: vi.fn(),
}));

const mockSearchMedia = vi.mocked(searchMedia);
const mockAddToWatchlist = vi.mocked(addToWatchlist);

const renderSearchPage = (user: User | null = null) => {
  const authValue: AuthContextType = {
    user,
    isAuthenticated: Boolean(user),
    loading: false,
    login: vi.fn(),
    logout: vi.fn(),
  };

  return render(
    <AuthContext.Provider value={authValue}>
      <MemoryRouter
        initialEntries={['/search']}
        future={{ v7_startTransition: true, v7_relativeSplatPath: true }}
      >
        <Routes>
          <Route path="/search" element={<Search />} />
        </Routes>
      </MemoryRouter>
    </AuthContext.Provider>
  );
};

describe('Search + Watchlist integration flows', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it('types in search input, triggers API search, and renders results', async () => {
    const user = userEvent.setup();

    mockSearchMedia.mockResolvedValue({
      data: {
        results: [
          {
            imdbID: 'tt1375666',
            title: 'Inception',
            year: '2010',
            type: 'movie',
            poster: 'N/A',
          },
        ],
      },
    } as any);

    renderSearchPage();

    await user.type(screen.getByPlaceholderText('Search movies or TV shows...'), 'inc');

    await waitFor(() => {
      expect(mockSearchMedia).toHaveBeenCalledWith('inc');
    });

    expect(await screen.findByText('Inception')).toBeTruthy();
    expect(screen.getByText('1 result')).toBeTruthy();
  });

  it('clicks Add to Watchlist and shows success feedback', async () => {
    const userEventInstance = userEvent.setup();

    mockSearchMedia.mockResolvedValue({
      data: {
        results: [
          {
            imdbID: 'tt0372784',
            title: 'Batman Begins',
            year: '2005',
            type: 'movie',
            poster: 'N/A',
          },
        ],
      },
    } as any);

    mockAddToWatchlist.mockResolvedValue({ data: {} } as any);

    renderSearchPage({
      _id: 'u1',
      username: 'student',
      email: 'student@example.com',
    });

    await userEventInstance.type(
      screen.getByPlaceholderText('Search movies or TV shows...'),
      'bat'
    );

    const addButton = await screen.findByRole('button', { name: /\+ watchlist/i });
    await userEventInstance.click(addButton);

    await waitFor(() => {
      expect(mockAddToWatchlist).toHaveBeenCalledWith({
        imdbID: 'tt0372784',
        status: 'plan_to_watch',
        title: 'Batman Begins',
        poster: 'N/A',
      });
    });

    expect(await screen.findByText('Added to watchlist!')).toBeTruthy();
  });
});
