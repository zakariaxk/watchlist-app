# watchlist-app

## Backend Setup

1. Use the project Node version:

```bash
nvm install
nvm use
```

2. Install backend dependencies:

```bash
cd server
npm install
```

3. Create your local environment file:

```bash
cp .env.example .env
```

4. Fill in your own values in `.env`:

- `PORT`
- `MONGO_URI`
- `JWT_SECRET`
- `FRONTEND_URL`
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_SECURE`
- `SMTP_USER`
- `SMTP_PASS`
- `EMAIL_FROM`

Email verification and password reset emails are sent only when SMTP settings are configured.

5. Optional local admin test account (private/local use only):

- Set `ENABLE_TEST_ADMIN=true` in `server/.env`
- Set your own `TEST_ADMIN_USERNAME`, `TEST_ADMIN_EMAIL`, and `TEST_ADMIN_PASSWORD`

This bypass is disabled by default and never enabled in production.

6. Run the backend:

```bash
npm run dev
```

## Production Deployment (Real Website)

Set these values in `server/.env` (or your host's secret manager) before deploying:

- `NODE_ENV=production`
- `PORT` (provided by your host if applicable)
- `MONGO_URI`
- `JWT_SECRET` (long random secret, at least 32 chars)
- `OMDB_API_KEY`
- `FRONTEND_URL` (for verification/reset links)
- `CORS_ORIGINS` (comma-separated real frontend domains)
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_SECURE`
- `SMTP_USER`
- `SMTP_PASS`
- `EMAIL_FROM`

Production safety rules already enforced by code:

- Test-admin bypass is disabled in production.
- `JWT_SECRET` must be set in production.
- `CORS_ORIGINS` must be set in production.

Recommended deployment checks:

1. `npm ci && npm run build && npm start` in `server`
2. `npm ci && npm run build` in `client`
3. Verify `GET /api/health` returns `{"status":"ok"}`
4. Test register -> verification email -> login flow on your real domain
5. Test forgot-password -> reset link email -> password reset flow on your real domain