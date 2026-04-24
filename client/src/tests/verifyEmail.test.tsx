import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { cleanup, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import VerifyEmail from '../pages/VerifyEmail';
import { verifyEmail as verifyEmailApi } from '../api/mediaApi';

vi.mock('../api/mediaApi', () => ({
  verifyEmail: vi.fn(),
}));

const mockVerifyEmail = vi.mocked(verifyEmailApi);

describe('VerifyEmail page', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it('shows invalid message when token missing', async () => {
    render(
      <MemoryRouter
        initialEntries={['/verify-email']}
        future={{ v7_startTransition: true, v7_relativeSplatPath: true }}
      >
        <Routes>
          <Route path="/verify-email" element={<VerifyEmail />} />
        </Routes>
      </MemoryRouter>
    );

    expect(await screen.findByText(/invalid verification link/i)).toBeTruthy();
  });

  it('calls API and shows success message on verify', async () => {
    mockVerifyEmail.mockResolvedValue({ data: { message: 'ok' } } as any);

    render(
      <MemoryRouter
        initialEntries={['/verify-email?token=abc']}
        future={{ v7_startTransition: true, v7_relativeSplatPath: true }}
      >
        <Routes>
          <Route path="/verify-email" element={<VerifyEmail />} />
        </Routes>
      </MemoryRouter>
    );

    await waitFor(() => expect(mockVerifyEmail).toHaveBeenCalledWith('abc'));
    expect(await screen.findByText(/verified successfully/i)).toBeTruthy();
  });
});
