import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { cleanup, render, screen, waitFor, act, fireEvent } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import Profile from '../pages/Profile';
import { AuthContext, AuthContextType } from '../context/AuthContext';
import { getFriends, getProfile, searchUsers } from '../api/mediaApi';

vi.mock('../api/mediaApi', () => ({
  getProfile: vi.fn(),
  updateProfile: vi.fn(),
  searchUsers: vi.fn(),
  getFriends: vi.fn(),
  unfollowUser: vi.fn(),
}));

const mockGetProfile = vi.mocked(getProfile);
const mockGetFriends = vi.mocked(getFriends);
const mockSearchUsers = vi.mocked(searchUsers);

describe('Profile page user search', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it('debounces search and calls API after 2+ characters', async () => {
    mockGetProfile.mockResolvedValue({
      data: {
        _id: 'u1',
        username: 'me',
        email: 'me@example.com',
        profileVisibility: 'public',
        createdAt: new Date().toISOString(),
      },
    } as any);

    mockGetFriends.mockResolvedValue({ data: [] } as any);
    mockSearchUsers.mockResolvedValue({
      data: { users: [{ _id: 'u2', username: 'jane', profileVisibility: 'public' }] },
    } as any);

    const authValue: AuthContextType = {
      user: { _id: 'u1', username: 'me', email: 'me@example.com' },
      isAuthenticated: true,
      loading: false,
      login: vi.fn(),
      logout: vi.fn(),
    };

    render(
      <AuthContext.Provider value={authValue}>
        <MemoryRouter
          initialEntries={['/profile']}
          future={{ v7_startTransition: true, v7_relativeSplatPath: true }}
        >
          <Routes>
            <Route path="/profile" element={<Profile />} />
          </Routes>
        </MemoryRouter>
      </AuthContext.Provider>
    );

    await waitFor(() => expect(mockGetProfile).toHaveBeenCalled());

    const input = screen.getByPlaceholderText('Search users by username...');
    fireEvent.change(input, { target: { value: 'ja' } });

    // Uses a real timer debounce in the component.
    await act(async () => {
      await new Promise((resolve) => setTimeout(resolve, 450));
    });

    await waitFor(() => expect(mockSearchUsers).toHaveBeenCalledWith('ja'));
    expect(await screen.findByText('jane')).toBeTruthy();
  });
});
