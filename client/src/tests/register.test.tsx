import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import Register from '../pages/Register';
import { registerUser, resendVerificationEmail } from '../api/mediaApi';

vi.mock('../api/mediaApi', () => ({
  registerUser: vi.fn(),
  resendVerificationEmail: vi.fn(),
}));

const mockRegisterUser = vi.mocked(registerUser);
const mockResendVerificationEmail = vi.mocked(resendVerificationEmail);

describe('Register page', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  const renderRegister = () =>
    render(
      <MemoryRouter
        initialEntries={['/signup']}
        future={{ v7_startTransition: true, v7_relativeSplatPath: true }}
      >
        <Routes>
          <Route path="/signup" element={<Register />} />
        </Routes>
      </MemoryRouter>
    );

  it('rejects invalid email before calling API', async () => {
    const user = userEvent.setup();
    renderRegister();

    await user.type(screen.getByPlaceholderText('you@email.com'), 'not-an-email');
    await user.type(screen.getByPlaceholderText('Username'), 'student');
    await user.type(screen.getByPlaceholderText('Password'), 'StrongPass1!');

    fireEvent.submit(screen.getByRole('button', { name: /submit/i }).closest('form')!);

    expect(await screen.findByText(/valid email address/i)).toBeTruthy();
    expect(mockRegisterUser).not.toHaveBeenCalled();
  });

  it('submits registration and supports resend verification', async () => {
    const user = userEvent.setup();
    renderRegister();

    mockRegisterUser.mockResolvedValue({
      data: { message: 'Please check your email to verify your account.' },
    } as any);

    mockResendVerificationEmail.mockResolvedValue({
      data: { message: 'Verification email resent successfully.' },
    } as any);

    await user.type(screen.getByPlaceholderText('you@email.com'), 'student@example.com');
    await user.type(screen.getByPlaceholderText('Username'), 'student');
    await user.type(screen.getByPlaceholderText('Password'), 'StrongPass1!');

    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(await screen.findByText(/check your email/i)).toBeTruthy();

    await user.click(screen.getByRole('button', { name: /resend verification email/i }));
    expect(await screen.findByText(/resent successfully/i)).toBeTruthy();
  });
});
