# Launch database on Supabase (for API + admin web)

Use Supabase PostgreSQL as the database for **deli_backend** (Laravel API and office admin web).

---

## 1. Create a Supabase project

1. Go to **[supabase.com](https://supabase.com)** and sign in (or create an account).
2. Click **New project**.
3. Choose your **organization** and set:
   - **Name**: e.g. `deli` or `ok-delivery`
   - **Database password**: choose a strong password and **save it** (you need it for the connection string).
   - **Region**: pick the one closest to your users or your API host (e.g. Render).
4. Click **Create new project** and wait until the project is ready.

---

## 2. Where to find database host, port, etc.

1. Open **[Supabase Dashboard](https://supabase.com/dashboard)** and select your project.
2. Click the **gear icon** (Project Settings) in the left sidebar.
3. Click **Database** in the settings menu.
4. Scroll to **Connection string**.
5. Select the **URI** tab. You’ll see something like:
   ```text
   postgresql://postgres:[YOUR-PASSWORD]@db.xxxxxxxxxxxx.supabase.co:5432/postgres
   ```
   From that URI you can read:
   - **Host**: the part after `@` and before `:5432` → e.g. `db.xxxxxxxxxxxx.supabase.co`  
     (must be **one line**, no space or newline in the middle)
   - **Port**: `5432` (direct) or `6543` (pooler)
   - **Database**: `postgres`
   - **User**: `postgres`
   - **Password**: the one you set when creating the project (replace `[YOUR-PASSWORD]` in the URI)

6. Or click **“Connection parameters”** / **“View parameters”** to see **Host**, **Port**, **Database name**, and **User** in a list. Use the same password you set for the project.

**If you see "Not IPv4 compatible":** Use the **Session pooler** instead of Direct connection (click **Pooler settings**). The pooler gives an IPv4-compatible host (e.g. `aws-0-us-east-1.pooler.supabase.com`) and user `postgres.PROJECT_REF`. Use those in your `.env` so Laravel can connect from IPv4 networks.

---

## 3. Configure the Laravel backend

1. In the backend folder:
   ```bash
   cd deli_backend
   ```

2. If you don’t have a `.env` yet:
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```

3. Open `.env` and set the database to use Supabase.

   **Option A – Use connection URI (recommended)**  
   Comment out or remove any existing `DB_HOST`, `DB_PORT`, etc. and set:
   ```env
   DB_CONNECTION=pgsql
   DB_URL=postgresql://postgres.[PROJECT-REF]:[YOUR-PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
   ```
   Use the exact URI from Supabase (with your password and correct port: **6543** for Transaction, **5432** for Session).

   **Option B – Use individual fields**  
   From **Database** → **Connection string** → **Connection parameters** in Supabase, copy Host, Port, Database name, User, and Password. Then in `.env`:
   ```env
   DB_CONNECTION=pgsql
   DB_HOST=aws-0-[REGION].pooler.supabase.com
   DB_PORT=6543
   DB_DATABASE=postgres
   DB_USERNAME=postgres.[PROJECT-REF]
   DB_PASSWORD=your_database_password
   DB_SSLMODE=require
   ```
   Leave `DB_URL` empty or commented out when using this.

4. Save `.env`.

---

## 4. Run migrations and seed

From the `deli_backend` folder:

```bash
php artisan migrate
```

If you see errors about extensions, ensure the PHP `pdo_pgsql` extension is enabled (e.g. in `php.ini`).

Then seed the office users (for admin web login):

```bash
php artisan db:seed --class=OfficeUserSeeder
```

---

## 5. Start the API and admin web

```bash
php artisan serve
```

- **API**: `http://localhost:8000/api/...`
- **Admin web**: `http://localhost:8000/office` (login with the seeded office credentials).

---

## 6. (Optional) Use Supabase for production (e.g. Render)

- Create a **separate** Supabase project for production, or use the same one and a different database password.
- In your production environment (e.g. Render), set the same `DB_*` or `DB_URL` variables from **Environment** (not from `.env` in the repo).
- Run migrations in production once:
  ```bash
  php artisan migrate --force
  php artisan db:seed --class=OfficeUserSeeder --force
  ```

---

## Troubleshooting

| Issue | What to do |
|-------|------------|
| **Connection refused / timeout** | Check Supabase **Database** → **Connection pooling** is enabled; use the **pooler** host and port (6543 or 5432) from the connection string. |
| **SSL required** | Supabase needs SSL. Use `DB_SSLMODE=require` (default in config) or the URI from the dashboard (it includes SSL). |
| **Authentication failed** | Confirm the password in the URI or `DB_PASSWORD` is correct and URL-encoded if it has special characters. |
| **`pdo_pgsql` not found** | Enable the `pdo_pgsql` PHP extension and restart the web server or CLI. |

---

## Summary

1. Create a Supabase project and note the **database password**.
2. Copy the **connection string (URI)** from Project Settings → Database.
3. Set `DB_CONNECTION=pgsql` and `DB_URL=...` (or host/port/user/password) in `deli_backend/.env`.
4. Run `php artisan migrate` and `php artisan db:seed --class=OfficeUserSeeder`.
5. Run `php artisan serve` and use the API and admin web as usual.

Your API and admin web will then use the Supabase PostgreSQL database.
