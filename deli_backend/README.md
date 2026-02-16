# Deli Backend

Laravel API and office admin web app for the Deli delivery system. **Hosting:** web app on [Render](https://render.com), database on [Supabase](https://supabase.com) (PostgreSQL).

---

## Stack

- **Laravel** (PHP 8.2+) – API + Blade office UI  
- **Database** – Supabase PostgreSQL (no MySQL)  
- **Storage** – Supabase Storage (package images)  
- **Deploy** – Docker on Render  

---

## Local setup

### 1. Clone and install

```bash
git clone https://github.com/HaShiRaMaReiZo/deli_backend.git
cd deli_backend
composer install
cp .env.example .env
php artisan key:generate
```

### 2. Database (Supabase)

Create a project on [Supabase](https://supabase.com), then in **Project Settings → Database** get:

- Connection: use **Session pooler** (IPv4-friendly)
- Host, Port (6543), Database (`postgres`), User (`postgres.<project-ref>`), Password

Put them in `.env`:

```env
DB_CONNECTION=pgsql
DB_HOST=<pooler-host>
DB_PORT=6543
DB_DATABASE=postgres
DB_USERNAME=postgres.<project-ref>
DB_PASSWORD=<your-password>
DB_SSLMODE=require
```

See [SUPABASE_SETUP.md](./SUPABASE_SETUP.md) for details.

### 3. Optional: Supabase Storage + location tracker

For package images and live map:

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_KEY=<anon-or-service-role-key>
SUPABASE_BUCKET=package-images
LOCATION_TRACKER_URL=https://your-location-tracker-url
```

### 4. Run migrations and seed

```bash
php artisan migrate
php artisan db:seed --class=OfficeUserSeeder
```

For production, set strong passwords via env (see [Security](#security)).

### 5. Start server

```bash
php artisan serve
```

- API: `http://localhost:8000/api`  
- Office admin: `http://localhost:8000/office`  

---

## Deploy to Render (web) + Supabase (DB)

1. **Database:** Use your existing Supabase project (or create one). No Render database.
2. **Web service:** On [Render](https://render.com), create a **Web Service** from this repo.
   - **Root directory:** (repo root)
   - **Runtime:** Docker  
   - **Plan:** Free or paid
3. **Environment:** In Render, set all variables from [.env.example](./.env.example). Required: `APP_KEY`, `APP_URL`, `DB_*`, `SUPABASE_URL`, `SUPABASE_KEY`, `PORT=8000`. See [RENDER_DEPLOY_SUPABASE.md](./RENDER_DEPLOY_SUPABASE.md).
4. Deploy. Your app URL will be like `https://deli-backend.onrender.com`.

---

## Security

- **Never commit `.env`** – it’s in `.gitignore`. Use `.env.example` as a template.
- **Secrets** – Set `APP_KEY`, `DB_PASSWORD`, `SUPABASE_KEY` only in environment (Render dashboard or local `.env`).
- **Office users** – In production, set `SEEDER_SUPER_ADMIN_PASSWORD`, `SEEDER_OFFICE_MANAGER_PASSWORD`, `SEEDER_OFFICE_STAFF_PASSWORD` (and optional `SEEDER_*_EMAIL`) before running the seeder. Locally the seeder uses safe defaults.
- **Debug routes** – `/check-schema` and `/seed-users` are disabled in production unless `ENABLE_DEBUG_ROUTES` is set.

---

## Project layout

```
app/Http/Controllers/Api/   # API (auth, merchant, rider, office)
app/Http/Controllers/Web/   # Office Blade (login, dashboard, packages, riders, map)
app/Models/                 # Eloquent models
app/Services/               # SupabaseStorageService, etc.
config/                     # Laravel config
database/migrations/        # PostgreSQL migrations
database/seeders/           # OfficeUserSeeder
routes/api.php              # API routes
routes/web.php              # Web + office routes
resources/views/office/      # Office admin Blade views
```

---

## API overview

- **Auth:** `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/user`, `POST /api/auth/logout`
- **Merchant:** `GET/POST /api/merchant/packages`, drafts, live location
- **Rider:** `GET/PUT /api/rider/packages`, status, proof, COD, `POST /api/rider/location`
- **Office:** (web UI at `/office`; API under `role:office_*`)

All API routes (except register/login) use **Bearer token** (Laravel Sanctum).

---

## Docs

- [SUPABASE_SETUP.md](./SUPABASE_SETUP.md) – Database on Supabase  
- [RENDER_DEPLOY_SUPABASE.md](./RENDER_DEPLOY_SUPABASE.md) – Deploy web app on Render with Supabase  

---

## License

MIT
