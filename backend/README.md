# ⚙️ Obole • Backend

The **Fastify + TypeScript** server that saves Obole's data and guards it behind a single account, backed by PostgreSQL.

## Features

- **REST API** • versioned under `/v1`, split into focused modules (identity, state, health).
- **Single-user identity** • one six-digit code, read straight from the environment. No user table, no registration. JWT access + refresh sessions, and wrong codes throttled across every caller.
- **Document sync** • clients pull and replace the whole budget document (`GET`/`PUT /v1/state`), stored relationally and written in one transaction. Each write bumps a revision, and a write made from an older revision is refused, so the app and the web interface never erase each other's changes.
- **Hardened** • Helmet, CORS open to the web interface's origin only, rate limiting, Zod request validation, and a non-root Docker image.

## Stack

Node 24 · Fastify 5 · TypeScript · Prisma 7 · PostgreSQL · Zod

## API

| Method & path | Access | Purpose |
| --- | --- | --- |
| `POST /v1/identity/login` | public | Exchange `{ code }` for an access/refresh token pair |
| `POST /v1/identity/refresh` | public | Rotate a refresh token into a new pair |
| `POST /v1/identity/logout` | access | Revoke the caller's refresh session |
| `GET /v1/identity/me` | access | Return the signed-in account |
| `GET /v1/state` | access | Read the whole budget document and its `revision` |
| `PUT /v1/state` | access | Replace the whole budget document; `409` if the `revision` it names is out of date |
| `GET /v1/rates` | access | The latest euro reference rates |
| `GET /v1/rates/:date` | access | The reference rates of one past day |
| `GET /v1/health` | public | Liveness and database connectivity |

Every response is wrapped in `{ "data": … }`; errors are `{ "message": …, "data": … }`.

## Getting Started

**Prerequisites:** Node 24 and a PostgreSQL database.

1. Install dependencies

```bash
npm install
```

2. Configure your environment

```bash
cp .env.example .env
```

Fill in `DATABASE_URL`, choose your six-digit `IDENTITY_CODE`, set a long random `JWT_SECRET` (≥ 32 chars), and list the web interface's origin in `CORS_ORIGIN` (comma-separated if there are several; leave it empty to allow no browser origin at all, since the iOS app doesn't need it).

3. Apply the database migrations

```bash
npm run db:migrate
```

4. Start the server

```bash
npm run dev
```

The API is live; verify it with `GET /v1/health`.

## Identity

The only account is opened by the code in your environment:

```bash
IDENTITY_CODE="483921"
```

`POST /v1/identity/login` compares the submitted code against this one in constant time and, on success, returns a short-lived access token plus a long-lived refresh token whose session is persisted (so logout and rotation are real). To change the code, edit the environment and restart; sessions already open stay open until they are signed out or lapse.

A six-digit code has only a million values, so guessing is kept expensive: each address gets five attempts a minute, and after ten wrong codes in fifteen minutes (from anywhere), every sign-in is refused until the oldest one ages out. Devices already signed in are unaffected.

## Scripts

| Script | Does |
| --- | --- |
| `npm run dev` | Start with hot reload |
| `npm run build` | Compile to `dist/` |
| `npm start` | Deploy migrations, then run |
| `npm test` | Run the Vitest suite |
| `npm run lint` | Lint with ESLint |
| `npm run db:migrate` | Create & apply a dev migration |
| `npm run db:deploy` | Apply migrations (production) |

## Docker

A multi-stage, non-root image lives at `.docker/Dockerfile`:

```bash
docker build -f .docker/Dockerfile -t obole-backend .
```
