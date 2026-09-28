# 🖥️ My Budget — Web

The **web interface** of My Budget: the same budget as the iOS app, in the browser — light, calm and Apple-like. Open it, type your six-digit code, and everything is there.

## Features

- **Budget** — the ring with what is left to spend, the spent, days-left and per-day figures, and every category against its limit. Step back through past months; a past month is measured against the budget frozen when it ended.
- **History** — operations grouped by day with day totals, a search, and a filter chip per category.
- **New & edit operation** — amount in any currency with the euro equivalent at the rate of the operation's own day (bank markup included), category, name, note, date, online, place, recurring. Delete with a confirmation.
- **Limits** — the monthly budget and each category's limit, with what is left to dispatch.
- **Settings** — sync state, default currency, exchange rates, operation and category counts, reset, sign out.
- **Works on a phone too** — the tabs move to a bottom tab bar and sheets rise from the bottom edge.

## Stack

React 19 · TypeScript · Vite · Tailwind CSS · React Router · lucide · Zod — served by nginx.

## Signing in

The page asks for the six-digit code set in the backend's environment (`IDENTITY_CODE`). The session lives in the tab: a reload keeps it, closing the tab signs out, so the next visit asks for the code again.

## How it syncs

The page is a second client of the backend, next to the app, and both write the same budget document. An edit shows at once and is sent in the background, naming the revision it was made from. If the app wrote in between, the backend refuses it; the page reads the new revision and applies the edit again on top, so neither side erases the other. While it is open, the page also picks up what the app writes — when it comes back into view, when the connection returns, and every minute.

## Architecture

```
src/
├─ application/   Session, services, the operation editor, notices, layout
├─ components/    Sheet, alert, ring and bars, switch, icon tiles, navigation
├─ core/          API client, budget store (sync), rates, budget math, formatting
└─ pages/         One folder per tab (sign-in, budget, history, operations, settings)
```

The budget math, formatting and currency rules mirror the app's `BudgetMath`, `Formatting` and `Currency`, so every figure lands on the same euro on both.

## Local Development

**Prerequisites:** Node 24 and the backend running.

1. Install dependencies

```bash
npm install
```

2. Point the development server at the backend

```bash
cp .env.example .env
```

`API_URL` is where `/v1` is forwarded — `http://localhost:8080` by default.

3. Start it

```bash
npm run dev
```

## Scripts

| Script | Does |
| --- | --- |
| `npm run dev` | Start the development server |
| `npm run build` | Type-check and build to `dist/` |
| `npm run preview` | Serve the build locally |
| `npm test` | Run the Vitest suite |
| `npm run lint` | Lint with ESLint |

## Docker

A multi-stage, non-root image lives at `.docker/Dockerfile`. nginx serves the page and forwards `/v1` to the backend, so the browser only ever talks to one origin:

```bash
docker build -f .docker/Dockerfile -t my-budget-web .
```

```bash
docker run -p 8080:8080 -e API_URL=https://my-budget.mael-bertocchi.fr my-budget-web
```

`API_URL` defaults to the production backend and must not end with a slash. The page is served with a strict Content-Security-Policy and is kept out of search engines.
