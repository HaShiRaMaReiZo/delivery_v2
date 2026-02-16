# Deployment: Render (web) + Supabase (database)

This project is designed to run with:

- **Web app** → [Render](https://render.com) (Docker)
- **Database** → [Supabase](https://supabase.com) (PostgreSQL)

No Render database and no other providers are required.

---

## 1. Database (Supabase)

Create a project on [Supabase](https://supabase.com) and get the connection details from **Project Settings → Database**. Use the **Session pooler** (IPv4-friendly).

See **[SUPABASE_SETUP.md](./SUPABASE_SETUP.md)** for step-by-step setup and `.env` configuration.

---

## 2. Deploy web app (Render)

1. Push this repo to GitHub.
2. On [Render](https://render.com): **New +** → **Web Service** → connect the repo.
3. **Root directory:** leave empty (repo root is this backend).
4. **Runtime:** Docker.
5. **Environment:** Add all variables from [.env.example](./.env.example). Required: `APP_KEY`, `APP_URL`, `DB_*`, `SUPABASE_URL`, `SUPABASE_KEY`, `PORT=8000`.

Full checklist and table: **[RENDER_DEPLOY_SUPABASE.md](./RENDER_DEPLOY_SUPABASE.md)**.

---

## 3. After deploy

- Set **APP_URL** in Render to your live URL (e.g. `https://deli-backend.onrender.com`).
- Run migrations on first deploy (handled by the Docker entrypoint).
- Seed office users once; in production set `SEEDER_SUPER_ADMIN_PASSWORD` (and other `SEEDER_*` env vars) before seeding.

---

## Summary

| What        | Where    |
|------------|----------|
| Web (API + office UI) | Render (Docker) |
| Database   | Supabase (PostgreSQL) |
| Package images | Supabase Storage |

See [README.md](./README.md) for local setup and security notes.
