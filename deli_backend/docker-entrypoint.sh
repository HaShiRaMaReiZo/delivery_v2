#!/bin/sh
# Don't use set -e, handle errors manually to prevent restart loops
# set -e

# Clear any cached config first (in case of errors)
echo "Clearing cached configuration..."
php artisan config:clear || true
php artisan route:clear || true
php artisan view:clear || true

# IMPORTANT: Don't cache routes in production to avoid stale route issues
# Route caching can cause issues with dynamic responses
# Cache only config and views, but NOT routes
echo "Caching Laravel configuration..."
php artisan config:cache || {
    echo "ERROR: Failed to cache config. Continuing anyway..."
    php artisan config:clear || true
}
# Skip route caching - let routes load dynamically
# php artisan route:cache || {
#     echo "WARNING: Failed to cache routes. Continuing anyway..."
# }
php artisan view:cache || {
    echo "WARNING: Failed to cache views. Continuing anyway..."
}

# Create storage directories if they don't exist
# Note: package_images are now stored in Supabase, but keeping delivery_proofs and cod_proofs local for now
mkdir -p storage/app/public/delivery_proofs || true
mkdir -p storage/app/public/cod_proofs || true

# Create storage link (symlink from public/storage to storage/app/public)
php artisan storage:link || true

# Verify symlink exists
if [ ! -L public/storage ]; then
    echo "Warning: Storage symlink not created. Attempting manual creation..."
    ln -sf ../storage/app/public public/storage || true
fi

# Run database migrations (safe on startup in Render free plan)
echo "Running database migrations..."
php artisan migrate --force --verbose || {
    echo "ERROR: Migrations failed. Checking migration status..."
    php artisan migrate:status || true
    echo "Attempting to continue anyway..."
}

# Seed database with initial users (super admin, etc.)
echo "Seeding database with initial users..."
php artisan db:seed --class=OfficeUserSeeder --force || {
    echo "WARNING: Seeding failed. This might be normal if already seeded."
}

# Start PHP built-in server using PORT from environment (default to 8000)
# Use php -S instead of artisan serve for better compatibility
PORT=${PORT:-8000}
echo "Starting PHP server on port $PORT..."

# Verify public directory exists
if [ ! -d "public" ]; then
    echo "ERROR: public directory not found!"
    exit 1
fi

# Verify index.php exists
if [ ! -f "public/index.php" ]; then
    echo "ERROR: public/index.php not found!"
    exit 1
fi

echo "Server is ready! Listening on port $PORT"
echo "Health check endpoint: http://0.0.0.0:$PORT/up"

# Use exec to replace shell process with PHP server
# This ensures proper signal handling and prevents restart loops
# The server will run indefinitely until stopped
# Redirect stderr to stdout so Render can see all logs
exec php -S 0.0.0.0:$PORT -t public 2>&1

