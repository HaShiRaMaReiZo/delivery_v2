# Deli - Delivery Management System

A comprehensive delivery management system with web and mobile applications for managing packages, riders, and deliveries.

## Current architecture (what you use today)

| Role | App / Service | Purpose |
|------|----------------|--------|
| **Frontend (mobile)** | **ok_delivery** | Merchant/customer app: register packages, drafts, track deliveries, live map |
| **Frontend (mobile)** | **rider_v2_app** | Rider app: assignments, update status, location, proof, COD |
| **API + Admin web** | **deli_backend** | Laravel API (`/api/*`) + office admin (Blade: dashboard, packages, riders, map, register user) |
| **Real-time** | **location_tracker_js** | Node.js Socket.io server for live rider location (used by backend map + ok_delivery) |

- **ok_delivery** and **rider_v2_app** both call the same backend: `https://ok-delivery-service.onrender.com` (deli_backend).
- **deli_backend** serves the **REST API** for the apps and the **admin web UI** (office login, dashboard, packages, riders, map, etc.) at the same domain.

## Project Structure

```
deli/
├── deli_backend/          # Laravel: API + office admin web
├── location_tracker_js/   # Node.js Socket.io – real-time rider location
├── ok_delivery/           # Flutter merchant/customer app
└── rider_v2_app/          # Flutter rider app
```

## Components

### 1. Backend API + Admin Web (`deli_backend/`)
Laravel 11: **REST API** for mobile apps and **office admin** (web).

**API** (`/api/*`): auth, merchant packages/drafts, rider packages/location, office packages/riders.

**Admin web** (Blade, `/office/*`): login, dashboard, packages, riders, map, register user. Used by office staff / super admin.

**Documentation:** [Backend README](./deli_backend/README.md), [Deployment](./deli_backend/DEPLOYMENT.md).

### 2. Merchant / Customer App (`ok_delivery/`)
Flutter app for merchants: register packages, drafts, track packages, live tracking map (Socket.io).

### 3. Rider App (`rider_v2_app/`)
Flutter app for riders: view assignments, update status, send location to location_tracker_js, proof, COD.

### 4. Location tracker (`location_tracker_js/`)
Node.js + Socket.io. Riders send location here; office map and ok_delivery consume live location.

## Quick Start

### Backend (API + admin web)
```bash
cd deli_backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed --class=OfficeUserSeeder
php artisan serve
```
Then open `http://localhost:8000` for office login and admin.

### Merchant app (ok_delivery)
```bash
cd ok_delivery
flutter pub get
flutter run
```

### Rider app (rider_v2_app)
```bash
cd rider_v2_app
flutter pub get
flutter run
```

## Deployment

See [Backend Deployment Guide](./deli_backend/DEPLOYMENT.md) for deploying to Render. Frontend apps (ok_delivery, rider_v2_app) point to the deployed backend URL in their `api_endpoints.dart`.

## Default Credentials (office admin web)

**Super Admin (Office):**
- Email: `erickboyle@superadmin.com`
- Password: `erick2004`

⚠️ **Change these credentials in production!**

## Technology Stack

- **Backend**: Laravel 11, PHP 8.2+ (API + Blade admin)
- **Mobile**: Flutter (ok_delivery, rider_v2_app)
- **Real-time**: Socket.io (location_tracker_js)
- **Deployment**: Docker, Render

## License

MIT License

