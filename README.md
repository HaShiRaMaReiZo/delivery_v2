# Deli - Delivery Management System

A comprehensive delivery management system with web and mobile applications for managing packages, riders, and deliveries.

## Project Structure

```
deli/
├── deli_backend/          # Laravel backend API
├── location_tracker_js/   # Node.js Socket.io server for real-time rider location
├── rider_app/             # Flutter rider mobile app
├── rider_v2_app/          # Flutter rider app (updated)
├── merchant_app/          # Flutter merchant mobile app
└── ok_delivery/           # Flutter merchant/customer app
```

## Components

### 1. Backend API (`deli_backend/`)
Laravel 11 REST API for package management, rider assignments, and real-time tracking.

**Features:**
- Package registration and tracking
- Rider assignment and location tracking
- Office web interface
- Real-time notifications
- COD collection tracking

**Documentation:**
- [Backend README](./deli_backend/README.md)
- [Deployment Guide](./deli_backend/DEPLOYMENT.md)

### 2. Rider App (`rider_app/`)
Flutter mobile application for delivery riders.

**Features:**
- View assigned packages
- Update package status
- Location tracking
- COD collection
- Delivery proof upload

### 3. Merchant App (`merchant_app/`)
Flutter mobile application for merchants to register and track packages.

**Features:**
- Package registration
- Package tracking
- Delivery status updates

## Quick Start

### Backend Setup
```bash
cd deli_backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed --class=OfficeUserSeeder
php artisan serve
```

### Rider App Setup
```bash
cd rider_app
flutter pub get
flutter run
```

### Merchant App Setup
```bash
cd merchant_app
flutter pub get
flutter run
```

## Deployment

See [Backend Deployment Guide](./deli_backend/DEPLOYMENT.md) for deploying to Render.

## Default Credentials

**Super Admin (Office):**
- Email: `erickboyle@superadmin.com`
- Password: `erick2004`

⚠️ **Change these credentials in production!**

## Technology Stack

- **Backend**: Laravel 11, PHP 8.2, MySQL
- **Mobile**: Flutter, Dart
- **Real-time**: WebSocket (Pusher)
- **Deployment**: Docker, Render

## License

MIT License

