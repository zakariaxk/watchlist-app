# WatchIt Frontend

React single-page app for WatchIt. It handles authentication flows, OMDb-backed media discovery, watchlist management, profiles, and social features by calling the backend API under `/api`.

## Live Demo

[http://watch-it.xyz](http://watch-it.xyz)

## Tech Stack

- React 18 + TypeScript
- Vite
- React Router
- Axios
- Vitest + Testing Library

## Environment Variables

Create `client/.env` from `client/.env.example`:

```bash
cp .env.example .env
```

- `VITE_API_URL`: backend base URL (must include `/api`)
  - Local example: `http://localhost:5001/api`
  - Deployed example: `http://watch-it.xyz/api`

## Run Locally

1. Install dependencies:

```bash
npm install
```

2. Start the dev server:

```bash
npm run dev
```

The app runs at `http://localhost:5173` by default.

## Scripts

- `npm run dev`: start Vite dev server
- `npm run build`: production build to `dist/`
- `npm run preview`: serve `dist/` locally
- `npm run lint`: ESLint checks
- `npm run test`: run unit/integration tests (Vitest)

## Architecture Notes

- API calls live in `src/api/` and use an Axios client that reads `VITE_API_URL`.
- Auth uses a JWT stored in `localStorage` and attached as a `Bearer` token on requests.
- Route configuration lives in `src/App.tsx`; protected pages use `src/components/ProtectedRoute.tsx`.

## Project Structure

- `src/pages/`: page-level routes (login/signup, search, watchlist, profile, detail pages)
- `src/components/`: shared UI components
- `src/api/`: API client and typed request wrappers
- `src/context/`: auth state and session persistence
- `src/styles/`: page/component styling
- `src/utils/`: validation and helpers
- `src/assets/`: images and icons