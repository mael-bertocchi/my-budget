# ⚙️ My Budget — Backend

The **Fastify + TypeScript** server that saves My Budget's data and guards it behind a single account — backed by PostgreSQL.

## Features

- **REST API** — versioned under `/v1`, split into focused modules (identity, state, health).
- **Single-user identity** — one username and password, read straight from the environment. No user table, no registration. JWT access + refresh sessions, per-route rate limiting.
- **Document sync** — the client pulls and replaces its whole budget document (`GET`/`PUT /v1/state`), stored relationally and written in one transaction.
- **Hardened** — Helmet, rate limiting, Zod request validation, and a non-root Docker image.

## Stack

Node 24 · Fastify 5 · TypeScript · Prisma 7 · PostgreSQL · Zod

## API

| Method & path | Access | Purpose |
| --- | --- | --- |
| `POST /v1/identity/login` | — | Exchange `{ username, password }` for an access/refresh token pair |
| `POST /v1/identity/refresh` | — | Rotate a refresh token into a new pair |
| `POST /v1/identity/logout` | access | Revoke the caller's refresh session |
| `GET /v1/identity/me` | access | Return the signed-in account |
| `GET /v1/state` | access | Read the whole budget document |
| `PUT /v1/state` | access | Replace the whole budget document |
| `GET /v1/health` | — | Liveness and database connectivity |

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

Fill in `DATABASE_URL`, choose your `IDENTITY_USERNAME` / `IDENTITY_PASSWORD`, and set a long random `JWT_SECRET` (≥ 32 chars).

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

The only account is the one in your environment:

```bash
IDENTITY_USERNAME="you"
IDENTITY_PASSWORD="something-long-and-secret"
```

`POST /v1/identity/login` compares the submitted credentials against these values in constant time and, on success, returns a short-lived access token plus a long-lived refresh token whose session is persisted (so logout and rotation are real). To change the credentials, edit the environment and restart — any existing tokens simply stop matching.

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
docker build -f .docker/Dockerfile -t my-budget-backend .
```
