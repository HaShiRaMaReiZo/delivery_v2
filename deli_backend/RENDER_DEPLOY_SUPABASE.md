# Deploy backend on Render (no card required – use Supabase)

You can host the Laravel API and office admin on **Render** free tier and keep using **Supabase** as the database. Render free tier does not require a credit card.

---

## 1. Sign up and connect repo

1. Go to **[render.com](https://render.com)** and sign up (e.g. with GitHub).
2. Click **New +** → **Web Service**.
3. Connect your **GitHub** repo (e.g. `HaShiRaMaReiZo/deli_backend`).
4. Set:
   - **Root Directory**: leave empty (repo root is the backend)
   - **Name**: `deli-backend` (or any name)
   - **Region**: Choose one (e.g. Oregon).
   - **Branch**: `main` (or your default).
   - **Runtime**: **Docker** (Render will use the `Dockerfile` in `deli_backend`).
   - **Plan**: **Free**.

---

## 2. Environment variables (Supabase + secrets)

In the Render service → **Environment** tab, add these. Use **Secret** for sensitive values.

| Key | Value | Secret? |
|-----|--------|--------|
| `APP_KEY` | From `php artisan key:generate --show` or your `.env` | Yes |
| `APP_URL` | `https://deli-backend.onrender.com` (or your Render URL after first deploy) | No |
| `DB_CONNECTION` | `pgsql` | No |
| `DB_HOST` | Your Supabase pooler host (e.g. `aws-1-ap-south-1.pooler.supabase.com`) | No |
| `DB_PORT` | `6543` | No |
| `DB_DATABASE` | `postgres` | No |
| `DB_USERNAME` | `postgres.<project-ref>` (from Supabase pooler) | No |
| `DB_PASSWORD` | Your Supabase database password | **Yes** |
| `DB_SSLMODE` | `require` | No |
| `PORT` | `8000` | No |
| `SUPABASE_URL` | `https://<project-ref>.supabase.co` | No |
| `SUPABASE_KEY` | Your Supabase anon or service role key | **Yes** |
| `SUPABASE_BUCKET` | `package-images` | No |
| `LOCATION_TRACKER_URL` | Your Socket.io tracker URL (optional) | No |

Get values from **Supabase Dashboard → Project Settings → Database** (DB_*) and **API** (SUPABASE_URL, SUPABASE_KEY).

---

## 3. Deploy

1. Click **Create Web Service**.
2. Render will build from the Dockerfile and deploy. First deploy can take a few minutes.
3. When it’s live, your URL will be like: `https://deli-backend.onrender.com`.
4. Set **APP_URL** in Environment to that URL (e.g. `https://deli-backend.onrender.com`) and **Save** (redeploy if needed).

---

## 4. After deploy

- **API**: `https://<your-app-name>.onrender.com/api/...`
- **Office admin**: `https://<your-app-name>.onrender.com/office`

Free tier may spin down after inactivity; the first request after a while can be slow.
