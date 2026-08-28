<div align="center">

# 💶 My Budget

### A calm place for every euro.

Log an operation, scan the history ledger, and watch the monthly budget — in any currency, always with the euro next to it.

`iOS 26 · SwiftUI` &nbsp;•&nbsp; `Liquid Glass` &nbsp;•&nbsp; `Multi-currency` &nbsp;•&nbsp; `Offline-first` &nbsp;•&nbsp; `Self-hosted backend`

</div>

---

## Why My Budget

- 🎯 **One glance, one number** — a budget ring that tells you what is left to spend, and how much that is per remaining day.
- 🧾 **A ledger you can read** — operations grouped by day, with day totals, search, and filters by category.
- 📍 **Where you spent it** — one tap on the location field fills in the place you are standing in.
- 🌍 **Any currency, always in euros** — enter in USD, CHF, KRW… the euro equivalent is computed live and shown next to the original amount.
- 🚦 **Limits that speak up** — per-category limits, with the bar and the amount turning red the moment you go over.
- ☁️ **Saved on your own server** — sign in once and every change syncs to a self-hosted backend; the app keeps working offline and reconciles when it's back.
- 🔒 **Yours to own** — a single account, its password living only in the backend's environment. No sign-ups, no third parties.

## What's inside

| Component | What it does |
| --- | --- |
| **[Frontend](frontend/README.md)** | The iOS application (SwiftUI). |
| **[Backend](backend/README.md)** | A Fastify + PostgreSQL server that stores your budget behind a single account. |

## Under the hood

**Application** — Swift · SwiftUI · Observation · iOS 26 Liquid Glass materials
**Backend** — Node 24 · Fastify 5 · TypeScript · Prisma 7 · PostgreSQL · JWT

## Layout

```
my-budget/
├─ frontend/   iOS application (SwiftUI)
└─ backend/    Fastify server (TypeScript)
```

Pick a side — **[run the application](frontend/README.md)** or **[spin up the server](backend/README.md)**.
