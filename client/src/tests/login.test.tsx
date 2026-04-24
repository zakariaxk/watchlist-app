import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { cleanup, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import Login from '../pages/Login';
import { AuthContext, AuthContextType, User } from '../context/AuthContext';
import { loginUser } from '../api/mediaApi';

vi.mock('../api/mediaApi', () => ({
  loginUser: vi.fn(),
}));

const mockLoginUser = vi.mocked(loginUser);

const renderLogin = (authOverrides?: Partial<AuthContextType>) => {
  const baseAuth: AuthContextType = {
    user: null,
    isAuthenticated: false,
    loading: false,
    login: vi.fn(),
    logout: vi.fn(),
  };

  const authValue: AuthContextType = { ...baseAuth, ...authOverrides } as AuthContextType;

  return render(
    <AuthContext.Provider value={authValue}>
      <MemoryRouter
        initialEntries={['/login']}
        future={{ v7_startTransition: true, v7_relativeSplatPath: true }}
      >
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={<div>Home</div>} />
        </Routes>
      </MemoryRouter>
    </AuthContext.Provider>
  );
};

describe('Login page', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it('logs in and navigates home', async () => {
    const user = userEvent.setup();

    const loginSpy = vi.fn();
    const apiUser: User = { _id: 'u1', username: 'student', email: 'student@example.com' };

    mockLoginUser.mockResolvedValue({
      data: { user: apiUser, token: 'token123' },
    } as any);

    renderLogin({ login: loginSpy });

    await user.type(screen.getByPlaceholderText('Username'), 'student');
    await user.type(screen.getByPlaceholderText('Password'), 'Passw0rd!');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      expect(mockLoginUser).toHaveBeenCalledWith('student', 'Passw0rd!');
    });

    expect(loginSpy).toHaveBeenCalledWith(apiUser, 'token123');
    expect(await screen.findByText('Home')).toBeTruthy();
  });

  it('shows backend error message on failure', async () => {
    const user = userEvent.setup();

    mockLoginUser.mockRejectedValue({
      response: { data: { message: 'Please verify your email before logging in.' } },
    });

    renderLogin();

    await user.type(screen.getByPlaceholderText('Username'), 'student');
    await user.type(screen.getByPlaceholderText('Password'), 'bad');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(await screen.findByText(/verify your email/i)).toBeTruthy();
  });
});
