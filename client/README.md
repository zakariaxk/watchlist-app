# Watchlist App Frontend

## Setup

1. Install dependencies:
```bash
npm install
```

2. Start development server:
```bash
npm run dev
```

The app will run at `http://localhost:5173`

## Backend URL

The frontend connects to: `http://poosdproject.space:5001/api`

For production builds, set `VITE_API_URL` to your real backend API URL.

Example:

```bash
VITE_API_URL=https://api.yourdomain.com/api
```

## Project Structure

- `src/components/` - Reusable UI components
- `src/pages/` - Full page views
- `src/api/` - API request functions
- `src/context/` - React Context for auth state
- `src/styles/` - CSS files
- `src/utils/` - Helper functions
- `src/assets/` - Images and icons
