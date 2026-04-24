# WatchIt

WatchIt is a full-stack watchlist platform for tracking movies and TV shows, reviewing titles, and seeing community activity. The project combines a React frontend, an Express API, MongoDB persistence, and OMDb search/detail data into a single web application.

## Live Demo

[http://watch-it.xyz](http://watch-it.xyz)

## Features

- Account registration, login, email verification, and password reset
- Search movies and TV shows through OMDb
- Save titles to a personal watchlist with status, rating, and favorites
- View title details, reviews, and review comments
- Public and private profiles
- Follow users and browse a friends activity feed
- Genre preferences and recommendation-oriented flows
- Optional Flutter mobile client that points to the same API

## Tech Stack

### Frontend

- React 18
- TypeScript
- Vite
- React Router
- Axios
- Vitest + Testing Library

### Backend

- Node.js 24
- Express 5
- TypeScript
- MongoDB + Mongoose
- JWT authentication
- Nodemailer / SendGrid-compatible email delivery
- Helmet, CORS, and rate limiting

### External Services

- OMDb API for search and media metadata

## Architecture

WatchIt is organized as a small monorepo:

- `client/`: React SPA for authentication, search, watchlists, profiles, and feed views
- `server/`: Express API for auth, watchlist, reviews, social graph, and OMDb-backed media endpoints
- `mobile-integration/`: Flutter client that reuses the same backend API

The frontend talks to the backend through `/api`. The backend stores application data in MongoDB, fetches searchable media metadata from OMDb, and serves the built frontend in production from `client/dist`. Authentication is token-based with JWT, and protected routes use an authorization middleware.

## Installation

### Prerequisites

- Node.js `24.10.0` or newer
- npm
- MongoDB instance
- OMDb API key

### Setup

```bash
git clone <repo-url>
cd watchlist-app
cd server && npm install
cd ../client && npm install
```

Create local environment files:

```bash
cp server/.env.example server/.env
cp client/.env.example client/.env
```

## Environment Variables

### Backend (`server/.env`)

- `PORT`: API port, default `5001`
- `MONGO_URI`: MongoDB connection string
- `JWT_SECRET`: JWT signing secret
- `OMDB_API_KEY`: OMDb API key
- `FRONTEND_URL`: frontend origin used in email links
- `NODE_ENV`: `development` or `production`
- `CORS_ORIGINS`: comma-separated allowed browser origins
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_SECURE`
- `SMTP_USER`
- `SMTP_PASS`
- `SENDGRID_API_KEY`
- `EMAIL_FROM`
- `ENABLE_TEST_ADMIN` and `TEST_ADMIN_*`: optional local-only bootstrap admin account

### Frontend (`client/.env`)

- `VITE_API_URL`: backend base URL, for example `http://localhost:5001/api`

## Run Locally

### Backend

```bash
cd server
npm run dev
```

The API starts on `http://localhost:5001` by default.

### Frontend

```bash
cd client
npm run dev
```

The Vite app starts on `http://localhost:5173`.

## API Overview

### Core Route Groups

- `/api/auth`: register, login, profile, email verification, resend verification, forgot/reset password
- `/api/media`: title search and media detail lookup through OMDb
- `/api/watchlist`: create, read, update, and delete watchlist items
- `/api/reviews`: create reviews and list reviews by `imdbID`
- `/api/review-comments`: create comments on reviews and list comments by review
- `/api/users`: username search and public profile lookup
- `/api/friends`: follow, unfollow, follow-status checks, and friend list
- `/api/feed`: public activity feed and authenticated friends feed
- `/api/health`: deployment health check

### Example Endpoints

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/media/search?title=inception&type=movie`
- `GET /api/media/tt1375666`
- `GET /api/watchlist`
- `POST /api/watchlist`
- `PUT /api/watchlist/:id`
- `DELETE /api/watchlist/:id`

## Deployment

Production deployment is straightforward:

1. Build the frontend with Vite.
2. Build or start the backend server.
3. Point the server at MongoDB, OMDb, and email credentials through environment variables.
4. Serve the React build from the Express app.

In production, Express serves `client/dist`, exposes the API under `/api`, enforces configured CORS origins, and uses the same deployment for both the SPA and backend routes. The live deployment is available at `watch-it.xyz`.

## Known Issues / Limitations

- Media search quality is limited by OMDb and currently relies on exact or near-exact title matching.
- Feed and watchlist metadata enrichment can add extra latency when cached title/poster data is missing.
- The mobile client exists as a separate integration layer and is not packaged into the main web deployment.

## Future Improvements

- Improved search with better ranking and filters
- Data enrichment to reduce repeated OMDb lookups and provide richer cached metadata