# Backend Guide (Beginner Friendly)

This file is your personal walkthrough of how the backend works right now.

Scope of this guide:
- What each backend file does
- Where each route lives
- How requests move from client to database and back
- How authentication works
- What each API endpoint expects and returns

Main source folder:
- `server/src`

---

## 1) Big Picture: How the Backend Runs

Think of the backend as a restaurant:
- `server.ts` is the front door opening the restaurant.
- `app.ts` is the manager that decides where each order (HTTP request) should go.
- Route files (`routes/*.ts`) are waiters for each section (auth, media, watchlist, comments).
- Model files (`models/*.ts`) are the official menu/data rules in MongoDB.
- `config/db.ts` connects the restaurant to the pantry (MongoDB).
- `middleware/auth.ts` checks customer identity (JWT token) before protected actions.

Flow at startup:
1. `server.ts` loads environment values (`.env`).
2. `server.ts` calls `connectDB()` from `config/db.ts`.
3. If DB connects, server listens on `PORT`.
4. Requests enter `app.ts`, then get forwarded to matching route file.

---

## 2) File-by-File Map

### `server/src/server.ts`
Purpose:
- Starts the backend process.

What it does:
- Loads environment variables with `dotenv`.
- Imports `app` from `app.ts`.
- Imports and runs `connectDB()`.
- Calls `app.listen(port)`.

Why this matters:
- If this file is not running, the API is offline.

### `server/src/app.ts`
Purpose:
- Creates Express app and global middleware.

What it does:
- Enables CORS with an allow-list of origins.
- Enables JSON request body parsing (`express.json()`).
- Mounts route groups:
  - `/api/auth` -> `authRoutes`
  - `/api/media` -> `mediaRoutes`
  - `/api/watchlist` -> `watchlistRoutes`
  - `/api/comments` -> `commentRoutes`
- Serves static frontend files from `client/dist`.
- Returns API 404 JSON for unknown API routes.
- Returns `client/dist/index.html` for non-API paths.

Why this matters:
- This file is the traffic controller for all endpoints.

### `server/src/config/db.ts`
Purpose:
- Connects Mongoose to MongoDB.

What it does:
- Reads `MONGO_URI` (falls back to local URI if missing).
- Calls `mongoose.connect()`.
- Logs success or exits process on failure.

Why this matters:
- Without DB connection, routes that read/write data fail.

### `server/src/middleware/auth.ts`
Purpose:
- Protect routes using JWT.

What it does:
- Reads `Authorization: Bearer <token>` header.
- Extracts token and verifies with `JWT_SECRET`.
- If valid, stores `{ id }` on `req.user`.
- If missing/invalid, returns `401`.

Why this matters:
- Prevents unauthenticated users from changing protected data.

### `server/src/models/User.ts`
Purpose:
- Defines user data shape and password logic.

Schema fields:
- `email` (required, unique, lowercase, trimmed)
- `password` (required)
- timestamps (`createdAt`, `updatedAt`)

Extra logic:
- Pre-save hook hashes password with `bcryptjs` before storing.
- Instance method `comparePassword()` compares plaintext vs hash.

Why this matters:
- Passwords are never stored in plain text.

### `server/src/models/Media.ts`
Purpose:
- Defines media catalog items.

Fields:
- `title` (required)
- `type` (`movie | tv | anime`, required)
- `genres` (array)
- `releaseYear`, `description`, `posterUrl`
- timestamps

### `server/src/models/Watchlist.ts`
Purpose:
- Defines user watchlist entries.

Fields:
- `userId` -> `User` reference
- `mediaId` -> `Media` reference
- `status` (`plan_to_watch | watching | completed`)
- `rating` (1 to 5)
- timestamps

### `server/src/models/Comment.ts`
Purpose:
- Defines comments users leave on media.

Fields:
- `userId` -> `User` reference
- `mediaId` -> `Media` reference
- `commentText` (required)
- `rating` (1 to 5)
- timestamps

---

## 3) Routes and APIs

All routes are mounted in `app.ts` under `/api/...`.

## Auth Routes (`server/src/routes/authRoutes.ts`)
Base path: `/api/auth`

### `POST /api/auth/register`
What it expects in body:
- `email`
- `password`

What happens:
1. Validates both fields exist.
2. Checks if user email already exists.
3. Creates new user.
4. `User` model hook hashes password automatically.
5. Creates JWT token.
6. Returns user data and token.

Current response shape:
- success: `201`
- body includes `message`, `user`, `token`

Potential note:
- Route currently uses `{ id: newUser._id }` in token payload and fallback secret if env is missing.

### `POST /api/auth/login`
What it expects in body:
- `email`
- `password`

What happens:
1. Validates both fields exist.
2. Finds user by email.
3. Compares password with `comparePassword()`.
4. Generates JWT.
5. Returns user and token.

Current response shape:
- success: `200`
- body includes `message`, `user`, `token`

---

## Media Routes (`server/src/routes/mediaRoutes.ts`)
Base path: `/api/media`

### `GET /api/media`
- Returns all media documents.

### `GET /api/media/:id`
- Returns one media item by Mongo ObjectId.
- Returns `404` if not found.

### `POST /api/media`
- Creates new media.
- Requires `title` and `type`.
- No auth check in this route yet.

---

## Watchlist Routes (`server/src/routes/watchlistRoutes.ts`)
Base path: `/api/watchlist`

### `GET /api/watchlist/:userId`
- Returns watchlist for provided `userId`.
- Uses `.populate("mediaId")` to include media details.
- Not protected by auth middleware currently.

### `POST /api/watchlist`
- Protected by `authenticate` middleware.
- Body expects `mediaId`, optional `status`, optional `rating`.
- `userId` is read from verified token (`req.user?.id`).
- Prevents duplicate watchlist entries.

### `PUT /api/watchlist/:id`
- Protected by `authenticate`.
- Updates `status` and/or `rating`.

### `DELETE /api/watchlist/:id`
- Protected by `authenticate`.
- Deletes one watchlist item.

---

## Comment Routes (`server/src/routes/commentRoutes.ts`)
Base path: `/api/comments`

### `GET /api/comments/:mediaId`
- Gets all comments for a media item.
- Populates commenter info (`email`).

### `POST /api/comments`
- Protected by `authenticate`.
- Requires `mediaId`, `commentText`.
- Uses token user id as `userId`.

---

## 4) How Files Communicate (Request Lifecycle)

Example: login request (`POST /api/auth/login`)
1. Frontend sends JSON to server URL + `/api/auth/login`.
2. Request enters Express app in `app.ts`.
3. `app.ts` forwards to `authRoutes.ts`.
4. Route reads request body and validates fields.
5. Route queries `User` model (`User.findOne`).
6. Mongoose fetches from MongoDB through active DB connection.
7. Route compares password hash using model method.
8. Route signs JWT and sends JSON response.

Example: add watchlist item (`POST /api/watchlist`)
1. Frontend sends token in header `Authorization: Bearer <token>`.
2. `authenticate` middleware verifies token.
3. Middleware sets `req.user.id`.
4. Route uses `req.user.id` + body `mediaId`.
5. Route writes new record through `Watchlist` model.
6. JSON response is returned.

---

## 5) Auth and Security Basics (Freshman Version)

Password hashing:
- Plain passwords should never go into DB.
- Hashing turns password into irreversible string.
- During login, app hashes input and compares securely.

JWT token:
- After login/register, server sends token.
- Token proves identity on later requests.
- Client stores token and sends it in Authorization header.

Middleware role:
- Middleware runs before route handler.
- If token bad/missing, middleware blocks request with `401`.

---

## 6) Environment Variables You Need

In `server/.env`:
- `PORT=5001`
- `MONGO_URI=...`
- `JWT_SECRET=...`

Why:
- Keeps sensitive values outside source code.
- Different machines can use different local values.

---

## 7) Where to Look When Something Breaks

Server not starting:
- Check `server.ts`
- Check `PORT` in `.env`

DB errors:
- Check `config/db.ts`
- Check `MONGO_URI`

401 Unauthorized:
- Check `middleware/auth.ts`
- Make sure request header uses `Bearer <token>`

404 route not found:
- Check mount path in `app.ts`
- Check route path in route file

Validation errors:
- Check required fields in route handlers and model schemas

---

## 8) Current Reality vs Planned Cleanup

Current codebase already includes auth + media + watchlist + comments.
That is wider than your original auth-only milestone.

When you want to refocus on lab checkoff auth only, keep these as your high-priority files:
- `server/src/server.ts`
- `server/src/app.ts`
- `server/src/config/db.ts`
- `server/src/models/User.ts`
- `server/src/routes/authRoutes.ts`
- `server/.env`

---

## 9) Quick Mental Model to Remember

- `server.ts`: start app + connect DB
- `app.ts`: register middleware + route groups
- `routes/*`: parse request + call models + return JSON
- `models/*`: schema + DB behavior
- `middleware/auth.ts`: verify token before protected routes
- `config/db.ts`: connect to MongoDB

If you remember this chain, you can debug most backend problems:
Request -> App -> Route -> Model -> DB -> Response
