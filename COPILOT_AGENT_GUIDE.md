# Copilot Agent Guide — watchlist-app

Purpose
-------

This document contains the repository context and exact operational guidelines a Copilot-style coding agent needs to work effectively in this workspace. It covers project layout, tech stack, key files to inspect for common tasks, development and commit rules, verification steps to ensure code is functional before committing, and a feature-request template (current request: password reset).

Quick Project Snapshot
----------------------

- Root: `watchlist-app/` — monorepo-style layout for web client, server, and mobile integration.
- Client: `watchlist-app/client/` — React + Vite + TypeScript frontend (entry: `client/src/main.tsx`).
- Server: `watchlist-app/server/` — Node + TypeScript backend (bootstrap: `server/src/app.ts` / `server/src/server.ts`).
- Mobile: `watchlist-app/mobile-integration/` — Flutter project for mobile builds.

How the pieces interact
-----------------------

- The client calls the server API via the HTTP client utilities in `client/src/api/` (`apiClient.ts`, `mediaApi.ts`).
- Authentication flows live across `client/src/context/AuthContext.tsx` and server auth routes in `server/src/routes/`.

Important files and responsibilities
----------------------------------

- `client/`
  - `client/src/context/AuthContext.tsx` — central auth logic (token storage, login/logout, current user). Primary place to hook password-reset client flows.
  - `client/src/pages/` — UI pages: `Login.tsx`, `Register.tsx`, `VerifyEmail.tsx`, `Profile.tsx`, `Watchlist.tsx`, etc.
  - `client/src/api/` — `apiClient.ts` (base axios/fetch config), `mediaApi.ts` (domain endpoints).

- `server/`
  - `server/src/app.ts`, `server/src/server.ts` — Express/Koa/HTTP bootstrap + middleware.
  - `server/src/routes/` — route definitions (look for `auth` or `users` routes for authentication logic).
  - `server/src/models/` — data models (User model/schema). Add reset-related fields here when implementing password reset.
  - `server/.env` — environment variables (DO NOT commit secrets). Use `.env.example` when available.

- `mobile-integration/` — Flutter code. Only edit for mobile-specific flows.

Local setup & common commands
----------------------------

Prerequisites
- Node.js (LTS, e.g., >=18), npm or yarn, and optionally pnpm.
- Flutter SDK if working on `mobile-integration/`.

Typical developer start

1. Open workspace at `watchlist-app/`.
2. Client: `cd client && npm install` then `npm run dev` (Vite dev server).
3. Server: `cd server && npm install` then `npm run dev` (or `npm run start:dev` depending on scripts).
4. Mobile: `cd mobile-integration && flutter pub get` then `flutter run` (if testing on device/emulator).

If a script name differs, inspect `package.json` in `client/` and `server/` and use the appropriate script.

Environment variables
- Place secrets and provider keys in `server/.env` locally. Never commit production secrets. If a `.env.example` exists, copy it and fill values.

Coding, commit and PR guidelines (exact rules)
--------------------------------------------

1. Branching
   - Use feature branches: `feat/...`, `fix/...`, `chore/...` (e.g., `feat/password-reset`, `fix/login-bug`).

2. Commit messages (Conventional Commits). Always use the pattern:

   <type>(<scope>): <short summary>

   - Types commonly used here: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.
   - Example: `feat(auth): add password reset request endpoint`

3. PRs
   - Open a PR from the feature branch with a clear description: summary, what changed, how to test, and screenshots if UI changes.
   - Include a checklist in the PR description with the items below (Pre-commit checklist).

4. Code style
   - TypeScript: prefer explicit types, avoid `any`, enable strict mode where possible.
   - Use async/await and proper try/catch error handling for server code.
   - Follow existing patterns for state management in `AuthContext` and request flows.
   - Run `npx eslint . --ext .ts,.tsx` and `npx prettier --write .` before committing (or `npm run lint` / `npm run format` if scripts exist).

Pre-commit checklist — must pass before committing
-------------------------------------------------

- Linting passes: `npm run lint` or `npx eslint ...`.
- Formatting applied: `npx prettier --write .`.
- Unit and integration tests run (if present): `npm test`.
- Client builds: `cd client && npm run build` (sanity check).
- Server builds (if TypeScript build step exists): `cd server && npm run build`.
- Manual verification: run server and client and exercise changed flows in the browser/postman.
- No secrets committed: verify changes with `git status` and inspect diffs.

How to ensure code is functional (detailed verification steps)
-----------------------------------------------------------

1. Run linters and formatters.
2. Install dependencies and do a local build of both client and server.
3. Start the server and client simultaneously and run through the user flows the change impacts.
4. Use API tests or Postman to validate expected endpoints. Example curl tests:

   - Request password reset (example):

     curl -X POST -H "Content-Type: application/json" -d '{"email":"user@example.com"}' http://localhost:3000/api/auth/forgot-password

   - Reset password (example):

     curl -X POST -H "Content-Type: application/json" -d '{"token":"TOKEN","password":"NewP@ssw0rd"}' http://localhost:3000/api/auth/reset-password

5. Verify UI flows: request reset form, email link opens reset form, set new password, try login with new password.

Security and production notes
-----------------------------

- Never log secrets or tokens in plaintext.
- Hash passwords (bcrypt) and, for reset tokens, store a hash of the token, not the token itself.
- Add rate limiting to endpoints like `forgot-password` to prevent abuse.
- Do not reveal whether an email exists—return a generic success message on password-reset request to avoid user enumeration.

Feature request template (use when asking for work)
--------------------------------------------------

Title: 

Priority: (low|medium|high)

Motivation / Why:

Acceptance criteria (explicit):
- What endpoints should exist (method + path + body + response).
- What UI screens are needed (paths, fields, expected behavior).
- Tests required (unit/integration/manual steps).

Data/model changes: (fields to add/update in models)

Security considerations:

Suggested implementation notes:

Owner / Assignee:

Current feature requests
------------------------

1) Password Reset — PRIORITY: High

   Motivation: Allow users to reset forgotten passwords securely via email.

   Acceptance criteria:
   - User can request a password reset using their email (`POST /api/auth/forgot-password`).
   - Server sends an email with a single-use secure token link that expires (recommended: 1 hour).
   - User follows link to a frontend reset page and submits a new password (`POST /api/auth/reset-password`).
   - Token is invalidated after use or expiry.
   - Passwords are hashed with bcrypt; existing sessions may be optionally revoked after reset.
   - Tests exist covering token generation, expiry, and successful reset.

   Suggested API design (examples):
   - POST `/api/auth/forgot-password` { "email": "user@example.com" } -> 200 (generic success)
   - POST `/api/auth/reset-password` { "token": "<token>", "password": "<newPassword>" } -> 200 on success.

   Server implementation notes:
   - Add fields to the User model: `resetPasswordToken?: string`, `resetPasswordExpires?: Date`.
   - Generate a secure token server-side: `crypto.randomBytes(32).toString('hex')` and store a hash: `sha256(token)` in DB.
   - Set expiry (e.g., now + 1 hour).
   - Send email with link: `${FRONTEND_URL}/reset-password?token=${token}&email=${email}`.
   - On reset, hash incoming token, find a matching user with `resetPasswordExpires > Date.now()`, set the new hashed password, clear the token fields.
   - Rate-limit `forgot-password`. Return 200 for both existing and non-existing emails to avoid enumeration.

   Frontend implementation notes:
   - Add `ForgotPassword` page with form to submit an email.
   - Add `ResetPassword` page that reads `token` (and optionally `email`) from the query string and posts to `/api/auth/reset-password`.
   - Hook new pages into routing and navigation; update `AuthContext` as needed for logout/invalidation flows.

   Testing notes:
   - Unit tests for token generation and DB fields.
   - Integration test that simulates request -> email (using test mail provider) -> reset flow.
   - Manual test: use curl/postman and a real SMTP test account or dev mail trap.

   Security notes:
   - Store only a hashed token in DB.
   - Tokens should be cryptographically random and sufficiently long.
   - Enforce strong password rules on reset (document exact policy here).

Agent operational rules (for Copilot agent behavior)
-------------------------------------------------

- Always read `SKILL.md` files and project instructions before making repo changes.
- Before performing edits, run fast static analysis where possible: lint, type-check, and run the dev server.
- Never commit secrets or `.env` values. Update `.env.example` when new variables are required.
- Keep PRs focused and small. Make one logical change per branch.
- Use the feature request template above when asking for clarifications; populate the fields and confirm any missing details before coding.

Example commit and push workflow (exact commands)
-----------------------------------------------

1. Create a feature branch:

   git checkout -b feat/password-reset

2. Stage changes and commit with a descriptive message:

   git add <changed-files>
   git commit -m "feat(auth): add password reset request endpoint"

3. Push branch and open PR:

   git push -u origin feat/password-reset

If the CI or repository requires signed commits or a specific PR template, follow those additional rules.

Where to ask questions or request clarifications
-----------------------------------------------

- Open a GitHub Issue linking this file and use the Feature Request template above.
- For immediate clarifications, post a focused message in the team channel and include the PR link and acceptance criteria.

Next steps for me (agent)
-------------------------

- I created this guide in the repo; next I can implement the password reset backend endpoints and a minimal frontend flow if you want. Please confirm preferred email provider (SMTP credentials / SendGrid / other), password policy (min length, complexity), and whether to invalidate active sessions on password change.

-- END --
