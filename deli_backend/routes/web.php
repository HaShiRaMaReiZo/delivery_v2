<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Artisan;
use App\Http\Controllers\Web\AuthController;
use App\Http\Controllers\Web\OfficeController;

Route::get('/', function () {
	// If user is authenticated and has office role, redirect to office dashboard
	if (auth()->check()) {
		$user = auth()->user();
		$officeRoles = ['super_admin', 'office_manager', 'office_staff'];
		if (in_array($user->role, $officeRoles)) {
			return redirect()->route('office.dashboard');
		}
	}
	// If not authenticated, redirect to office login
	return redirect()->route('office.login');
});

// Handle Chrome DevTools requests gracefully
Route::get('/.well-known/appspecific/com.chrome.devtools.json', function () {
	return response()->json([]);
});

// Route to check database schema (diagnostic)
Route::get('/check-schema', function () {
	// Only allow in non-production environments unless explicitly enabled
	if (!app()->environment(['local', 'development', 'staging']) && !env('ENABLE_DEBUG_ROUTES', false)) {
		abort(404);
	}

	try {
		$hasIsDraft = \Illuminate\Support\Facades\Schema::hasColumn('packages', 'is_draft');
		
		// Check if tracking_code is nullable
		$trackingCodeNullable = false;
		try {
			$columns = \Illuminate\Support\Facades\DB::select("
				SELECT is_nullable 
				FROM information_schema.columns 
				WHERE table_name = 'packages' 
				AND column_name = 'tracking_code'
			");
			if (!empty($columns)) {
				$trackingCodeNullable = strtolower($columns[0]->is_nullable) === 'yes';
			}
		} catch (\Exception $e) {
			// Try MySQL syntax
			try {
				$columns = \Illuminate\Support\Facades\DB::select("
					SELECT IS_NULLABLE 
					FROM information_schema.COLUMNS 
					WHERE TABLE_NAME = 'packages' 
					AND COLUMN_NAME = 'tracking_code'
				");
				if (!empty($columns)) {
					$trackingCodeNullable = strtolower($columns[0]->IS_NULLABLE) === 'yes';
				}
			} catch (\Exception $e2) {
				// Ignore
			}
		}
		
		// Check migrations table
		$migrations = \Illuminate\Support\Facades\DB::table('migrations')
			->where('migration', 'like', '%is_draft%')
			->orWhere('migration', 'like', '%tracking_code%')
			->get();
		
		return response()->json([
			'has_is_draft_column' => $hasIsDraft,
			'tracking_code_nullable' => $trackingCodeNullable,
			'migrations_run' => $migrations->pluck('migration')->toArray(),
			'status' => ($hasIsDraft && $trackingCodeNullable) ? 'ready' : 'migrations_needed',
			'message' => ($hasIsDraft && $trackingCodeNullable) 
				? 'Database schema is correct' 
				: 'Migrations need to be run. The is_draft column or nullable tracking_code is missing.',
		]);
	} catch (\Exception $e) {
		return response()->json([
			'error' => $e->getMessage(),
			'trace' => $e->getTraceAsString(),
		], 500);
	}
});

// Route to seed users (useful for resetting database or initial setup)
Route::get('/seed-users', function () {
	// Only allow in non-production environments unless explicitly enabled
	if (!app()->environment(['local', 'development', 'staging']) && !env('ENABLE_DEBUG_ROUTES', false)) {
		abort(404);
	}

	try {
		Artisan::call('db:seed', ['--class' => 'OfficeUserSeeder', '--force' => true]);
		$output = Artisan::output();
		return response()->json([
			'success' => true,
			'message' => 'Users seeded successfully!',
			'output' => $output,
			'users' => [
				'Super Admin: erickboyle@superadmin.com / erick2004',
				'Office Manager: manager@delivery.com / manager123',
				'Office Staff: staff@delivery.com / staff123'
			]
		]);
	} catch (\Exception $e) {
		return response()->json([
			'success' => false,
			'message' => 'Error seeding users: ' . $e->getMessage()
		], 500);
	}
});

// Office Authentication
Route::prefix('office')->group(function () {
	Route::get('/login', [AuthController::class, 'showLogin'])->name('office.login')->middleware('guest');
	Route::post('/login', [AuthController::class, 'login'])->middleware('guest');
	
	// Protected routes
	Route::middleware('auth')->group(function () {
		Route::post('/logout', [AuthController::class, 'logout'])->name('office.logout');
		Route::get('/', [OfficeController::class, 'dashboard'])->name('office.dashboard');
		Route::get('/packages', [OfficeController::class, 'packages'])->name('office.packages');
		Route::get('/packages/registered-by-merchant', [OfficeController::class, 'registeredPackagesByMerchant'])->name('office.registered_packages_by_merchant');
		Route::get('/packages/picked-up', [OfficeController::class, 'pickedUpPackages'])->name('office.picked_up_packages');
		Route::get('/riders', [OfficeController::class, 'riders'])->name('office.riders');
		Route::get('/map', [OfficeController::class, 'map'])->name('office.map');
		Route::get('/register-user', [OfficeController::class, 'showRegisterUser'])->name('office.register_user');
		Route::post('/register-user', [OfficeController::class, 'registerUser'])->name('office.register_user.post');
	});
});
