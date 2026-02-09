<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\Merchant\PackageController as MerchantPackageController;
use App\Http\Controllers\Api\Rider\PackageController as RiderPackageController;
use App\Http\Controllers\Api\Rider\LocationController as RiderLocationController;
use App\Http\Controllers\Api\Office\PackageController as OfficePackageController;
use App\Http\Controllers\Api\Office\RiderController as OfficeRiderController;
use App\Http\Controllers\Api\NotificationController;

// Public routes
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

// Location store route (called by Node.js server, no auth required)
Route::post('/rider/location/store', [RiderLocationController::class, 'store']);

    // Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth routes
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/user', [AuthController::class, 'user']);

    // Notification routes
    Route::prefix('notifications')->group(function () {
        Route::post('/register-token', [NotificationController::class, 'registerToken']);
        Route::post('/unregister-token', [NotificationController::class, 'unregisterToken']);
    });

    // Merchant routes
    Route::prefix('merchant')->middleware('role:merchant')->group(function () {
        // Package routes (scoped to authenticated merchant)
        Route::get('/packages', [MerchantPackageController::class, 'index']);
        Route::post('/packages/bulk', [MerchantPackageController::class, 'bulkStore']);
        
        // Draft routes - MUST come before parameterized routes
        Route::post('/packages/draft', [MerchantPackageController::class, 'saveDraft']);
        Route::get('/packages/draft', [MerchantPackageController::class, 'getDrafts']);
        Route::post('/packages/draft/submit', [MerchantPackageController::class, 'submitDrafts']);
        Route::put('/packages/draft/{id}', [MerchantPackageController::class, 'updateDraft']);
        Route::delete('/packages/draft/{id}', [MerchantPackageController::class, 'deleteDraft']);
        
        // Parameterized routes - must come after specific routes
        Route::get('/packages/{id}', [MerchantPackageController::class, 'show']);
        Route::get('/packages/{id}/track', [MerchantPackageController::class, 'track']);
        Route::get('/packages/{id}/live-location', [MerchantPackageController::class, 'liveLocation']);
        Route::get('/packages/{id}/history', [MerchantPackageController::class, 'history']);
    });

    // Rider routes
    Route::prefix('rider')->middleware('role:rider')->group(function () {
        // Routes with rider_id in path - must come before routes without it
        Route::get('/packages/{rider_id}/history', [RiderPackageController::class, 'history']);
        
        // Routes without rider_id (uses authenticated user's rider_id)
        Route::get('/packages', [RiderPackageController::class, 'index']);
        Route::get('/packages/{id}', [RiderPackageController::class, 'show']);
        Route::put('/packages/{id}/status', [RiderPackageController::class, 'updateStatus']);
        Route::post('/packages/{id}/receive-from-office', [RiderPackageController::class, 'receiveFromOffice']);
        Route::post('/packages/{id}/start-delivery', [RiderPackageController::class, 'startDelivery']);
        Route::post('/packages/{id}/contact-customer', [RiderPackageController::class, 'contactCustomer']);
        Route::post('/packages/{id}/proof', [RiderPackageController::class, 'uploadProof']);
        Route::post('/packages/{id}/cod', [RiderPackageController::class, 'collectCod']);
        Route::post('/merchants/{merchantId}/confirm-pickup', [RiderPackageController::class, 'confirmPickupByMerchant']);
        
        // Location routes
        Route::post('/location', [RiderLocationController::class, 'update']);
        Route::get('/location', [RiderLocationController::class, 'current']);
    });

    // Office routes
    Route::prefix('office')->middleware('role:office_manager,office_staff,super_admin')->group(function () {
        // Package routes
        Route::get('/packages', [OfficePackageController::class, 'index']);
        Route::get('/packages/{id}', [OfficePackageController::class, 'show']);
        Route::put('/packages/{id}/status', [OfficePackageController::class, 'updateStatus']);
        Route::post('/packages/{id}/assign', [OfficePackageController::class, 'assign']);
        Route::post('/packages/bulk-assign', [OfficePackageController::class, 'bulkAssign']);
        Route::post('/merchants/{merchantId}/assign-pickup', [OfficePackageController::class, 'assignPickupByMerchant']);
        Route::get('/packages/arrived', [OfficePackageController::class, 'arrived']);
        
        // Rider routes - specific routes must come before parameterized routes
        Route::get('/riders', [OfficeRiderController::class, 'index']);
        Route::get('/riders/locations', [OfficeRiderController::class, 'locations']);
        Route::get('/riders/{id}', [OfficeRiderController::class, 'show']);
    });
});

