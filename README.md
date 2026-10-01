<div align="center">

# 🪙 Obole

### A calm place for every euro.

Log an operation, scan the history ledger, and watch the monthly budget — on your iPhone or in the browser, in any currency, always with the euro next to it.

`iOS 26 · SwiftUI` &nbsp;•&nbsp; `Liquid Glass` &nbsp;•&nbsp; `Web` &nbsp;•&nbsp; `Multi-currency` &nbsp;•&nbsp; `English & French` &nbsp;•&nbsp; `Offline-first` &nbsp;•&nbsp; `Self-hosted backend`

</div>

---

## Why Obole

- 🎯 **One glance, one number** — a budget ring that tells you what is left to spend, and how much that is per remaining day.
- 🧾 **A ledger you can read** — operations grouped by day, with day totals, search, and filters by category.
- 🌍 **Any currency, always in euros** — enter in USD, CHF, KRW… the euro equivalent is computed live and shown next to the original amount.
- 🚦 **Limits that speak up** — per-category limits, with the bar and the amount turning red the moment you go over.
- 🗣️ **In English or in French** — pick the language in Settings or let it follow your device; amounts and dates are written the way that language writes them.
- ☁️ **Saved on your own server** — sign in once and every change syncs to a self-hosted backend; the app keeps working offline and reconciles when it's back.
- 🖥️ **Also in the browser** — the same budget on a clean, light web page; the app and the page merge each other's changes instead of overwriting them.
- 🔒 **Yours to own** — a single account opened with a six-digit code that lives only in the backend's environment. No sign-ups, no third parties.

## What's inside

| Component | What it does |
| --- | --- |
| **[Frontend](frontend/README.md)** | The iOS application (SwiftUI). |
| **[Web](web/README.md)** | The web interface (React), light and Apple-like. |
| **[Backend](backend/README.md)** | A Fastify + PostgreSQL server that stores your budget behind a single account. |

## Under the hood

**Application** — Swift · SwiftUI · Observation · iOS 26 Liquid Glass materials
**Web** — React 19 · TypeScript · Vite · Tailwind CSS · Caddy
**Backend** — Node 24 · Fastify 5 · TypeScript · Prisma 7 · PostgreSQL · JWT

## Layout

```
obole/
├─ frontend/   iOS application (SwiftUI)
├─ web/        Web interface (React)
└─ backend/    Fastify server (TypeScript)
```

Pick a side — **[run the application](frontend/README.md)**, **[open the web interface](web/README.md)** or **[spin up the server](backend/README.md)**.
