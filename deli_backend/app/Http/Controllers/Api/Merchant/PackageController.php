<?php

namespace App\Http\Controllers\Api\Merchant;

use App\Http\Controllers\Controller;
use App\Models\Package;
use App\Models\PackageStatusHistory;
use App\Services\TrackingCodeService;
use App\Services\SupabaseStorageService;
use App\Events\PackageStatusChanged;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\QueryException;
use PDOException;

class PackageController extends Controller
{
    /**
     * Get packages for authenticated merchant
     * Route: GET /api/merchant/packages
     */
    public function index(Request $request)
    {
        $merchant = $request->user()->merchant;
        if (!$merchant) {
            return response()->json([
                'message' => 'Merchant profile not found',
            ], 404);
        }

        // Only load necessary relationships - statusHistory is heavy and not needed for list view
        // Only load specific columns to reduce data transfer
        // Exclude draft packages from regular list
        $packages = Package::where('merchant_id', $merchant->id)
            ->where('is_draft', false)
            ->with(['currentRider:id,name,phone', 'statusHistory' => function ($query) {
                // Only get the latest status history entry for each package
                // and include the user who changed it for proper display
                $query->with('changedBy')->orderBy('created_at', 'desc')->limit(1);
            }])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json($packages);
    }

    public function bulkStore(Request $request)
    {
        try {
            if (ob_get_level()) {
                ob_end_clean();
            }
            
            // Normalize empty strings to null for optional fields
            $packages = $request->packages;
            foreach ($packages as &$package) {
                // Handle package_description - if empty, set to null
                if (isset($package['package_description']) && empty(trim($package['package_description']))) {
                    $package['package_description'] = null;
                }
            }
            $request->merge(['packages' => $packages]);
            
            $request->validate([
                'packages' => 'required|array|min:1|max:50', // Limit to 50 packages per request
                'packages.*.customer_name' => 'required|string|max:255',
                'packages.*.customer_phone' => 'required|string|max:20',
                'packages.*.delivery_address' => 'required|string',
                'packages.*.delivery_latitude' => 'nullable|numeric',
                'packages.*.delivery_longitude' => 'nullable|numeric',
                'packages.*.payment_type' => 'required|in:cod,prepaid',
                'packages.*.amount' => 'required|numeric|min:0',
                'packages.*.package_description' => 'nullable|string',
                'packages.*.package_image' => 'nullable|string', // Base64 encoded image
            ]);

            $merchant = $request->user()->merchant;
            $packages = $request->packages;
            $createdPackages = [];
            $errors = [];
            $imageUploadErrors = []; // Track image upload errors

            foreach ($packages as $index => $packageData) {
                try {
                    // Generate unique tracking code
                    $trackingCode = TrackingCodeService::generate();

                    // Handle package image (base64 to Supabase)
                    $packageImageUrl = null;
                    $imageError = null;
                    if (!empty($packageData['package_image'])) {
                        try {
                            $base64String = $packageData['package_image'];
                            
                            // Remove data URL prefix if present (e.g., "data:image/jpeg;base64,")
                            if (strpos($base64String, ',') !== false) {
                                $base64String = explode(',', $base64String, 2)[1];
                            }
                            
                            // Decode base64 image
                            $imageData = base64_decode($base64String, true); // strict mode
                            
                            if ($imageData === false) {
                                $imageError = 'Failed to decode base64 image data';
                                Log::warning('Failed to decode base64 image', [
                                    'tracking_code' => $trackingCode,
                                    'base64_length' => strlen($packageData['package_image']),
                                    'base64_preview' => substr($packageData['package_image'], 0, 50) . '...'
                                ]);
                            } elseif (strlen($imageData) === 0) {
                                $imageError = 'Decoded image data is empty';
                                Log::warning('Decoded image data is empty', [
                                    'tracking_code' => $trackingCode
                                ]);
                            } else {
                                // Check if Supabase is configured
                                $supabaseUrl = env('SUPABASE_URL');
                                $supabaseKey = env('SUPABASE_KEY');
                                
                                if (empty($supabaseUrl) || empty($supabaseKey)) {
                                    $imageError = 'Supabase not configured (missing SUPABASE_URL or SUPABASE_KEY)';
                                    Log::error('Supabase credentials missing', [
                                        'tracking_code' => $trackingCode,
                                        'supabase_url_set' => !empty($supabaseUrl),
                                        'supabase_key_set' => !empty($supabaseKey)
                                    ]);
                                } else {
                                    // Generate unique filename
                                    $filename = 'package_' . $trackingCode . '_' . time() . '_' . uniqid() . '.jpg';
                                    $path = 'package_images/' . $filename;
                                    
                                    // Upload to Supabase Storage
                                    $supabase = new SupabaseStorageService();
                                    $supabaseErrorMessage = null;
                                    $packageImageUrl = $supabase->upload($path, $imageData, $supabaseErrorMessage);
                                    
                                    if ($packageImageUrl) {
                                        Log::info('Package image uploaded to Supabase', [
                                            'tracking_code' => $trackingCode,
                                            'path' => $path,
                                            'url' => $packageImageUrl,
                                            'size' => strlen($imageData)
                                        ]);
                                    } else {
                                        // Sanitize error message to ensure valid UTF-8 for JSON encoding
                                        $sanitizedError = $supabaseErrorMessage ?? 'Supabase upload failed (unknown error)';
                                        $sanitizedError = mb_convert_encoding($sanitizedError, 'UTF-8', 'UTF-8');
                                        $sanitizedError = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/', '', $sanitizedError);
                                        $imageError = substr($sanitizedError, 0, 200);
                                        
                                        Log::warning('Failed to upload package image to Supabase', [
                                            'tracking_code' => $trackingCode,
                                            'path' => $path,
                                            'image_size' => strlen($imageData),
                                            'supabase_url' => $supabaseUrl,
                                            'supabase_bucket' => env('SUPABASE_BUCKET', 'package-images'),
                                            'error' => $imageError
                                        ]);
                                    }
                                }
                            }
                        } catch (\Exception $e) {
                            // Sanitize exception message to ensure valid UTF-8 for JSON encoding
                            $exceptionMsg = mb_convert_encoding($e->getMessage(), 'UTF-8', 'UTF-8');
                            $exceptionMsg = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/', '', $exceptionMsg);
                            $imageError = 'Exception: ' . substr($exceptionMsg, 0, 200);
                            
                            Log::error('Failed to upload package image', [
                                'tracking_code' => $trackingCode,
                                'error' => $imageError,
                            ]);
                        }
                        
                        // Store image error for this package
                        if ($imageError) {
                            $imageUploadErrors[] = [
                                'tracking_code' => $trackingCode,
                                'error' => $imageError
                            ];
                        }
                    }

                    // Get current time in Myanmar timezone (UTC+6:30)
                    $myanmarTime = now()->setTimezone('Asia/Yangon');
                    
                    $package = Package::create([
                        'tracking_code' => $trackingCode,
                        'merchant_id' => $merchant->id,
                        'customer_name' => $packageData['customer_name'],
                        'customer_phone' => $packageData['customer_phone'],
                        'delivery_address' => $packageData['delivery_address'],
                        'delivery_latitude' => $packageData['delivery_latitude'] ?? null,
                        'delivery_longitude' => $packageData['delivery_longitude'] ?? null,
                        'payment_type' => $packageData['payment_type'],
                        'amount' => $packageData['amount'],
                        'package_image' => $packageImageUrl,
                        'package_description' => $packageData['package_description'] ?? null,
                        'status' => 'registered',
                        'registered_at' => $myanmarTime,
                    ]);

                    // Log status history
                    PackageStatusHistory::create([
                        'package_id' => $package->id,
                        'status' => 'registered',
                        'changed_by_user_id' => $request->user()->id,
                        'changed_by_type' => 'merchant',
                        'created_at' => now(),
                    ]);

                    // Broadcast status change via WebSocket
                    event(new PackageStatusChanged($package->id, 'registered', $package->merchant_id));

                    $createdPackages[] = $package;
                } catch (\Exception $e) {
                    $errors[] = [
                        'index' => $index,
                        'customer_name' => $packageData['customer_name'] ?? 'Unknown',
                        'error' => $e->getMessage(),
                    ];
                }
            }

            return response()->json([
                'message' => count($createdPackages) . ' package(s) created successfully',
                'created_count' => count($createdPackages),
                'failed_count' => count($errors),
                'packages' => $createdPackages,
                'errors' => $errors,
                'image_upload_errors' => $imageUploadErrors, // Include image upload errors
            ], count($createdPackages) > 0 ? 201 : 422)->header('Content-Type', 'application/json');
        } catch (\Illuminate\Validation\ValidationException $e) {
            if (ob_get_level()) {
                ob_end_clean();
            }
            
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors(),
                'error_details' => 'Please check the validation errors and correct the input data.',
            ], 422)->header('Content-Type', 'application/json');
        } catch (\Exception $e) {
            Log::error('Bulk package creation error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            return response()->json([
                'message' => 'An error occurred while creating packages',
                'error' => $e->getMessage(),
            ], 500)->header('Content-Type', 'application/json');
        }
    }

    public function show(Request $request, $id)
    {
        $merchant = $request->user()->merchant;
        
        $package = Package::where('merchant_id', $merchant->id)
            ->with(['merchant', 'currentRider', 'statusHistory.changedBy', 'deliveryProof', 'codCollection'])
            ->findOrFail($id);

        return response()->json($package);
    }

    public function track(Request $request, $id)
    {
        $merchant = $request->user()->merchant;
        
        $package = Package::where('merchant_id', $merchant->id)
            ->with(['currentRider', 'statusHistory.changedBy'])
            ->findOrFail($id);

        return response()->json([
            'package' => $package,
            'status_history' => $package->statusHistory()
                ->with('changedBy')
                ->orderBy('created_at', 'desc')
                ->get(),
        ]);
    }

    public function liveLocation(Request $request, $id)
    {
        $merchant = $request->user()->merchant;
        
        $package = Package::where('merchant_id', $merchant->id)
            ->with('currentRider')
            ->findOrFail($id);

        $rider = $package->currentRider;
        
        // If status is delivered, return last location from status history
        if ($package->status === 'delivered') {
            $lastStatusHistory = \App\Models\PackageStatusHistory::where('package_id', $package->id)
                ->where('status', 'delivered')
                ->whereNotNull('latitude')
                ->whereNotNull('longitude')
                ->orderBy('created_at', 'desc')
                ->first();
            
            if ($lastStatusHistory && $lastStatusHistory->latitude && $lastStatusHistory->longitude) {
                return response()->json([
                    'rider' => $rider ? [
                        'id' => $rider->id,
                        'name' => $rider->name,
                        'latitude' => (float) $lastStatusHistory->latitude,
                        'longitude' => (float) $lastStatusHistory->longitude,
                        'last_update' => $lastStatusHistory->created_at,
                    ] : null,
                    'package' => [
                        'id' => $package->id,
                        'tracking_code' => $package->tracking_code,
                        'status' => $package->status,
                        'delivery_address' => $package->delivery_address,
                        'delivery_latitude' => $package->delivery_latitude,
                        'delivery_longitude' => $package->delivery_longitude,
                    ],
                    'is_live' => false, // Indicates this is last location, not live tracking
                ]);
            }
            
            // If no location in history, return error
            return response()->json([
                'message' => 'Package is delivered but no delivery location found',
                'location' => null,
                'package' => [
                    'id' => $package->id,
                    'tracking_code' => $package->tracking_code,
                    'status' => $package->status,
                ],
                'is_live' => false,
            ]);
        }

        // Only return live location if status is ready_for_delivery or on_the_way (in transit)
        if ($package->status !== 'on_the_way' && $package->status !== 'ready_for_delivery') {
            return response()->json([
                'message' => 'Package is not in transit',
                'location' => null,
                'package' => [
                    'id' => $package->id,
                    'tracking_code' => $package->tracking_code,
                    'status' => $package->status,
                ],
                'is_live' => false,
            ]);
        }
        
        if (!$rider) {
            return response()->json([
                'message' => 'No rider assigned',
                'location' => null,
                'package' => [
                    'id' => $package->id,
                    'tracking_code' => $package->tracking_code,
                    'status' => $package->status,
                ],
                'is_live' => false,
            ]);
        }

        return response()->json([
            'rider' => [
                'id' => $rider->id,
                'name' => $rider->name,
                'latitude' => $rider->current_latitude,
                'longitude' => $rider->current_longitude,
                'last_update' => $rider->last_location_update,
            ],
            'package' => [
                'id' => $package->id,
                'tracking_code' => $package->tracking_code,
                'status' => $package->status,
                'delivery_address' => $package->delivery_address,
                'delivery_latitude' => $package->delivery_latitude,
                'delivery_longitude' => $package->delivery_longitude,
            ],
            'is_live' => true, // Indicates this is live tracking
        ]);
    }

    public function history(Request $request, $id)
    {
        $merchant = $request->user()->merchant;
        
        $package = Package::where('merchant_id', $merchant->id)
            ->findOrFail($id);

        $history = PackageStatusHistory::where('package_id', $package->id)
            ->with('changedBy')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($history);
    }

    /**
     * Save packages as drafts (without tracking codes or status)
     */
    public function saveDraft(Request $request)
    {
        while (ob_get_level()) {
            ob_end_clean();
        }
        
        try {
            // Normalize empty strings to null for optional fields
            $packages = $request->packages;
            
            if (!is_array($packages) || empty($packages)) {
                return response()->json([
                    'message' => 'Validation failed',
                    'errors' => ['packages' => ['The packages field is required and must be a non-empty array.']],
                ], 422, ['Content-Type' => 'application/json']);
            }
            foreach ($packages as &$package) {
                if (isset($package['package_description']) && empty(trim($package['package_description']))) {
                    $package['package_description'] = null;
                }
            }
            $request->merge(['packages' => $packages]);

            $request->validate([
                'packages' => 'required|array|min:1|max:50',
                'packages.*.customer_name' => 'required|string|max:255',
                'packages.*.customer_phone' => 'required|string|max:20',
                'packages.*.delivery_address' => 'required|string',
                'packages.*.delivery_latitude' => 'nullable|numeric',
                'packages.*.delivery_longitude' => 'nullable|numeric',
                'packages.*.payment_type' => 'required|in:cod,prepaid',
                'packages.*.amount' => 'required|numeric|min:0',
                'packages.*.package_description' => 'nullable|string',
                'packages.*.package_image' => 'nullable|string', // Base64 encoded image
            ]);

            $merchant = $request->user()->merchant;
            $packages = $request->packages;
            $createdDrafts = [];
            $errors = [];
            $imageUploadErrors = [];

            foreach ($packages as $index => $packageData) {
                try {
                    // Handle package image (base64 to Supabase)
                    $packageImageUrl = null;
                    $imageError = null;
                    
                    if (!empty($packageData['package_image'])) {
                        try {
                            $base64String = $packageData['package_image'];
                            
                            if (strpos($base64String, ',') !== false) {
                                $base64String = explode(',', $base64String, 2)[1];
                            }
                            
                            $imageData = base64_decode($base64String, true);
                            
                            if ($imageData === false) {
                                $imageError = 'Failed to decode base64 image data';
                            } else {
                                try {
                                    // Generate unique filename for draft (no tracking code yet)
                                    $filename = 'draft_' . time() . '_' . uniqid() . '_' . $index . '.jpg';
                                    $path = 'package_images/' . $filename;
                                    
                                    $supabaseService = new SupabaseStorageService();
                                    $supabaseErrorMessage = null;
                                    $packageImageUrl = $supabaseService->upload($path, $imageData, $supabaseErrorMessage);
                                    
                                    if (!$packageImageUrl) {
                                        $imageError = $supabaseErrorMessage ?? 'Failed to upload image to Supabase';
                                    }
                                } catch (\Throwable $uploadEx) {
                                    $imageError = 'Failed to upload image: ' . $uploadEx->getMessage();
                                    Log::warning('Draft image upload error', [
                                        'index' => $index,
                                        'error' => $uploadEx->getMessage(),
                                    ]);
                                }
                            }
                        } catch (\Exception $e) {
                            $imageError = 'Failed to upload image: ' . $e->getMessage();
                            Log::warning('Draft image upload error', [
                                'index' => $index,
                                'error' => $e->getMessage(),
                            ]);
                        }
                    }

                    // Create draft package
                    $packageDataToSave = [
                        'merchant_id' => $merchant->id,
                        'customer_name' => $packageData['customer_name'],
                        'customer_phone' => $packageData['customer_phone'],
                        'delivery_address' => $packageData['delivery_address'],
                        'delivery_latitude' => $packageData['delivery_latitude'] ?? null,
                        'delivery_longitude' => $packageData['delivery_longitude'] ?? null,
                        'payment_type' => $packageData['payment_type'],
                        'amount' => $packageData['amount'],
                        'package_image' => $packageImageUrl,
                        'package_description' => $packageData['package_description'] ?? null,
                        'is_draft' => true,
                        'status' => null,
                    ];
                    
                    $package = Package::create($packageDataToSave);

                    if ($imageError) {
                        $imageUploadErrors[] = [
                            'index' => $index,
                            'customer_name' => $packageData['customer_name'],
                            'error' => $imageError,
                        ];
                    }

                    $createdDrafts[] = $package;
                } catch (\Throwable $e) {
                    Log::error('Error creating draft package', [
                        'index' => $index,
                        'error' => $e->getMessage(),
                        'type' => get_class($e),
                    ]);
                    $errors[] = [
                        'index' => $index,
                        'customer_name' => $packageData['customer_name'] ?? 'Unknown',
                        'error' => $e->getMessage(),
                    ];
                }
            }

            // Clean output buffer before sending response
            while (ob_get_level() > 0) {
                ob_end_clean();
            }
            
            // Convert packages to array for JSON response - use toArray() for safe serialization
            $packagesArray = [];
            foreach ($createdDrafts as $pkg) {
                try {
                    // Use toArray() which handles all serialization safely
                    $packageArray = $pkg->toArray();
                    
                    // Ensure proper types and handle nulls
                    $packagesArray[] = [
                        'id' => (int) $packageArray['id'],
                        'merchant_id' => (int) $packageArray['merchant_id'],
                        'customer_name' => (string) $packageArray['customer_name'],
                        'customer_phone' => (string) $packageArray['customer_phone'],
                        'delivery_address' => (string) $packageArray['delivery_address'],
                        'delivery_latitude' => isset($packageArray['delivery_latitude']) ? (float) $packageArray['delivery_latitude'] : null,
                        'delivery_longitude' => isset($packageArray['delivery_longitude']) ? (float) $packageArray['delivery_longitude'] : null,
                        'payment_type' => (string) $packageArray['payment_type'],
                        'amount' => (float) $packageArray['amount'],
                        'package_image' => $packageArray['package_image'] ?? null,
                        'package_description' => $packageArray['package_description'] ?? null,
                        'tracking_code' => $packageArray['tracking_code'] ?? null,
                        'status' => $packageArray['status'] ?? null, // May be null for drafts
                        'is_draft' => isset($packageArray['is_draft']) ? (bool) $packageArray['is_draft'] : false,
                        'registered_at' => $pkg->registered_at ? $pkg->registered_at->toIso8601String() : null,
                        'created_at' => $pkg->created_at->toIso8601String(),
                        'updated_at' => $pkg->updated_at->toIso8601String(),
                    ];
                } catch (\Exception $serializeEx) {
                    Log::warning('Error serializing package', [
                        'package_id' => $pkg->id ?? 'unknown',
                        'error' => $serializeEx->getMessage(),
                    ]);
                }
            }
            
            $responseData = [
                'message' => count($createdDrafts) . ' draft package(s) saved successfully',
                'created_count' => count($createdDrafts),
                'failed_count' => count($errors),
                'packages' => $packagesArray,
                'errors' => $errors,
                'image_upload_errors' => $imageUploadErrors,
            ];
            
            $statusCode = count($createdDrafts) > 0 ? 201 : 422;
            
            return response()->json($responseData, $statusCode, [
                'Content-Type' => 'application/json; charset=utf-8',
                'Cache-Control' => 'no-cache, no-store, must-revalidate',
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            if (ob_get_level()) {
                ob_end_clean();
            }
            
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422)->header('Content-Type', 'application/json');
        } catch (QueryException $e) {
            while (ob_get_level()) {
                ob_end_clean();
            }
            
            Log::error('Draft package save database error', [
                'error' => $e->getMessage(),
                'sql' => $e->getSql(),
                'bindings' => $e->getBindings(),
                'code' => $e->getCode(),
            ]);
            
            // Check if it's a constraint violation (likely tracking_code NOT NULL)
            $errorMessage = $e->getMessage();
            if (strpos($errorMessage, 'tracking_code') !== false || 
                strpos($errorMessage, 'null value') !== false ||
                strpos($errorMessage, 'NOT NULL') !== false ||
                $e->getCode() == '23502') { // PostgreSQL NOT NULL violation code
                return response()->json([
                    'message' => 'Database error: Please run migrations. The tracking_code column needs to be nullable for drafts.',
                    'error' => 'Database constraint violation. Migrations may not have been run.',
                    'details' => 'Error: ' . $errorMessage,
                ], 500, [
                    'Content-Type' => 'application/json',
                    'Cache-Control' => 'no-cache, no-store, must-revalidate',
                ]);
            }
            
            return response()->json([
                'message' => 'Database error occurred while saving drafts',
                'error' => $errorMessage,
            ], 500, [
                'Content-Type' => 'application/json',
                'Cache-Control' => 'no-cache, no-store, must-revalidate',
            ]);
        } catch (PDOException $e) {
            while (ob_get_level()) {
                ob_end_clean();
            }
            
            Log::error('Draft package save PDO error', [
                'error' => $e->getMessage(),
                'code' => $e->getCode(),
            ]);
            
            $errorMessage = $e->getMessage();
            if (strpos($errorMessage, 'tracking_code') !== false || 
                strpos($errorMessage, 'null value') !== false ||
                strpos($errorMessage, 'NOT NULL') !== false) {
                return response()->json([
                    'message' => 'Database error: Please run migrations. The tracking_code column needs to be nullable for drafts.',
                    'error' => 'Database constraint violation. Migrations may not have been run.',
                    'details' => 'Error: ' . $errorMessage,
                ], 500, [
                    'Content-Type' => 'application/json',
                    'Cache-Control' => 'no-cache, no-store, must-revalidate',
                ]);
            }
            
            return response()->json([
                'message' => 'Database error occurred while saving drafts',
                'error' => $errorMessage,
            ], 500, [
                'Content-Type' => 'application/json',
                'Cache-Control' => 'no-cache, no-store, must-revalidate',
            ]);
        } catch (\Throwable $e) {
            while (ob_get_level()) {
                ob_end_clean();
            }
            
            Log::error('Draft package save error', [
                'error' => $e->getMessage(),
                'type' => get_class($e),
            ]);
            
            return response()->json([
                'message' => 'An error occurred while saving drafts',
                'error' => $e->getMessage(),
            ], 500, [
                'Content-Type' => 'application/json',
                'Cache-Control' => 'no-cache, no-store, must-revalidate',
            ]);
        }
    }

    /**
     * Get all draft packages for the merchant
     */
    public function getDrafts(Request $request)
    {
        try {
            while (ob_get_level()) {
                ob_end_clean();
            }
            
            $merchant = $request->user()->merchant;
            
            $drafts = Package::where('merchant_id', $merchant->id)
                ->where('is_draft', true)
                ->orderBy('created_at', 'desc')
                ->get();

            // Manually serialize packages to handle null status
            $draftsArray = [];
            foreach ($drafts as $pkg) {
                try {
                    $packageArray = $pkg->toArray();
                    $draftsArray[] = [
                        'id' => (int) $packageArray['id'],
                        'merchant_id' => (int) $packageArray['merchant_id'],
                        'customer_name' => (string) $packageArray['customer_name'],
                        'customer_phone' => (string) $packageArray['customer_phone'],
                        'delivery_address' => (string) $packageArray['delivery_address'],
                        'delivery_latitude' => isset($packageArray['delivery_latitude']) ? (float) $packageArray['delivery_latitude'] : null,
                        'delivery_longitude' => isset($packageArray['delivery_longitude']) ? (float) $packageArray['delivery_longitude'] : null,
                        'payment_type' => (string) $packageArray['payment_type'],
                        'amount' => (float) $packageArray['amount'],
                        'package_image' => $packageArray['package_image'] ?? null,
                        'package_description' => $packageArray['package_description'] ?? null,
                        'tracking_code' => $packageArray['tracking_code'] ?? null,
                        'status' => $packageArray['status'] ?? null,
                        'is_draft' => isset($packageArray['is_draft']) ? (bool) $packageArray['is_draft'] : false,
                        'registered_at' => $pkg->registered_at ? $pkg->registered_at->toIso8601String() : null,
                        'created_at' => $pkg->created_at->toIso8601String(),
                        'updated_at' => $pkg->updated_at->toIso8601String(),
                    ];
                } catch (\Exception $e) {
                    Log::warning('Error serializing draft package', [
                        'package_id' => $pkg->id ?? 'unknown',
                        'error' => $e->getMessage(),
                    ]);
                }
            }

            return response()->json($draftsArray, 200, [
                'Content-Type' => 'application/json; charset=utf-8',
                'Cache-Control' => 'no-cache, no-store, must-revalidate',
            ]);
        } catch (\Throwable $e) {
            while (ob_get_level()) {
                ob_end_clean();
            }
            
            Log::error('Error getting drafts', [
                'error' => $e->getMessage(),
                'type' => get_class($e),
            ]);
            
            return response()->json([
                'message' => 'An error occurred while fetching drafts',
                'error' => $e->getMessage(),
            ], 500, [
                'Content-Type' => 'application/json',
                'Cache-Control' => 'no-cache, no-store, must-revalidate',
            ]);
        }
    }

    /**
     * Submit draft packages to the system (convert to regular packages)
     */
    public function submitDrafts(Request $request)
    {
        try {
            $request->validate([
                'package_ids' => 'required|array|min:1',
                'package_ids.*' => 'required|integer|exists:packages,id',
            ]);

            $merchant = $request->user()->merchant;
            $packageIds = $request->package_ids;
            
            // Get draft packages that belong to this merchant
            $draftPackages = Package::where('merchant_id', $merchant->id)
                ->where('is_draft', true)
                ->whereIn('id', $packageIds)
                ->get();

            if ($draftPackages->isEmpty()) {
                return response()->json([
                    'message' => 'No valid draft packages found',
                ], 404)->header('Content-Type', 'application/json');
            }

            $submittedPackages = [];
            $errors = [];

            foreach ($draftPackages as $package) {
                try {
                    // Generate tracking code
                    $trackingCode = TrackingCodeService::generate();

                    // Get current time in Myanmar timezone (UTC+6:30)
                    $myanmarTime = now()->setTimezone('Asia/Yangon');
                    
                    // Update package: set tracking code, status, is_draft = false, and registered_at
                    $package->update([
                        'tracking_code' => $trackingCode,
                        'status' => 'registered',
                        'is_draft' => false,
                        'registered_at' => $myanmarTime,
                    ]);

                    // Create initial status history entry
                    PackageStatusHistory::create([
                        'package_id' => $package->id,
                        'status' => 'registered',
                        'changed_by_id' => $merchant->user_id,
                        'changed_by_type' => 'merchant',
                        'created_at' => now(),
                    ]);

                    // Broadcast status change via WebSocket
                    event(new PackageStatusChanged($package->id, 'registered', $package->merchant_id));

                    $submittedPackages[] = $package;
                } catch (\Exception $e) {
                    $errors[] = [
                        'package_id' => $package->id,
                        'customer_name' => $package->customer_name,
                        'error' => $e->getMessage(),
                    ];
                }
            }

            return response()->json([
                'message' => count($submittedPackages) . ' package(s) submitted successfully',
                'submitted_count' => count($submittedPackages),
                'failed_count' => count($errors),
                'packages' => $submittedPackages,
                'errors' => $errors,
            ], count($submittedPackages) > 0 ? 200 : 422)->header('Content-Type', 'application/json');
        } catch (\Illuminate\Validation\ValidationException $e) {
            if (ob_get_level()) {
                ob_end_clean();
            }
            
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422)->header('Content-Type', 'application/json');
        } catch (\Exception $e) {
            if (ob_get_level()) {
                ob_end_clean();
            }
            
            Log::error('Draft submission error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            return response()->json([
                'message' => 'An error occurred while submitting drafts',
                'error' => $e->getMessage(),
            ], 500)->header('Content-Type', 'application/json');
        }
    }

    /**
     * Delete a draft package
     */
    public function deleteDraft(Request $request, $id)
    {
        try {
            $merchant = $request->user()->merchant;
            
            $package = Package::where('merchant_id', $merchant->id)
                ->where('is_draft', true)
                ->findOrFail($id);
            
            // Delete associated image from Supabase if exists
            if ($package->package_image) {
                try {
                    $supabaseService = new SupabaseStorageService();
                    $path = $supabaseService->extractPathFromUrl($package->package_image);
                    if ($path) {
                        $supabaseService->delete($path);
                    }
                } catch (\Exception $e) {
                    // Log but don't fail if image deletion fails
                    Log::warning('Failed to delete draft package image', [
                        'package_id' => $package->id,
                        'error' => $e->getMessage(),
                    ]);
                }
            }
            
            $package->delete();
            
            return response()->json([
                'message' => 'Draft package deleted successfully',
            ], 200, [
                'Content-Type' => 'application/json',
            ]);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'message' => 'Draft package not found',
                'error' => 'The specified draft package does not exist or does not belong to you.',
            ], 404, [
                'Content-Type' => 'application/json',
            ]);
        } catch (\Throwable $e) {
            Log::error('Error deleting draft package', [
                'package_id' => $id,
                'error' => $e->getMessage(),
            ]);
            
            return response()->json([
                'message' => 'An error occurred while deleting the draft',
                'error' => $e->getMessage(),
            ], 500, [
                'Content-Type' => 'application/json',
            ]);
        }
    }

    /**
     * Update a draft package
     */
    public function updateDraft(Request $request, $id)
    {
        try {
            $merchant = $request->user()->merchant;
            
            $package = Package::where('merchant_id', $merchant->id)
                ->where('is_draft', true)
                ->findOrFail($id);
            
            $validated = $request->validate([
                'customer_name' => 'required|string|max:255',
                'customer_phone' => 'required|string|max:20',
                'delivery_address' => 'required|string|max:500',
                'payment_type' => 'required|in:cod,prepaid',
                'amount' => 'required|numeric|min:0',
                'package_image' => 'nullable|string',
                'package_description' => 'nullable|string|max:1000',
            ]);
            
            // Handle image upload/update/delete
            if (isset($validated['package_image'])) {
                if (empty($validated['package_image'])) {
                    // Empty string means delete image
                    if ($package->package_image) {
                        try {
                            $supabaseService = new SupabaseStorageService();
                            $oldPath = $supabaseService->extractPathFromUrl($package->package_image);
                            if ($oldPath) {
                                $supabaseService->delete($oldPath);
                            }
                        } catch (\Exception $e) {
                            Log::warning('Failed to delete old draft package image', [
                                'package_id' => $package->id,
                                'error' => $e->getMessage(),
                            ]);
                        }
                    }
                    $validated['package_image'] = null;
                } else {
                    // New image provided - upload it
                    try {
                        $supabaseService = new SupabaseStorageService();
                        
                        // Delete old image if exists
                        if ($package->package_image) {
                            try {
                                $oldPath = $supabaseService->extractPathFromUrl($package->package_image);
                                if ($oldPath) {
                                    $supabaseService->delete($oldPath);
                                }
                            } catch (\Exception $e) {
                                // Log but continue
                                Log::warning('Failed to delete old draft package image', [
                                    'package_id' => $package->id,
                                    'error' => $e->getMessage(),
                                ]);
                            }
                        }
                        
                        // Upload new image
                        $imageData = base64_decode($validated['package_image']);
                        $fileName = 'draft_' . $package->id . '_' . uniqid() . '_' . time() . '.jpg';
                        $path = 'package_images/' . $fileName;
                        
                        $supabaseService->upload($path, $imageData, 'Failed to upload package image');
                        $validated['package_image'] = $supabaseService->getPublicUrl($path);
                    } catch (\Exception $e) {
                        Log::error('Error uploading package image', [
                            'package_id' => $package->id,
                            'error' => $e->getMessage(),
                        ]);
                        
                        return response()->json([
                            'message' => 'Failed to upload package image',
                            'error' => $e->getMessage(),
                        ], 500, [
                            'Content-Type' => 'application/json',
                        ]);
                    }
                }
            } else {
                // Keep existing image if no new image provided
                unset($validated['package_image']);
            }
            
            // Update package
            $package->update($validated);
            
            // Reload to get updated data
            $package->refresh();
            
            // Manually serialize to handle nullable status
            $packageData = [
                'id' => $package->id,
                'merchant_id' => $package->merchant_id,
                'customer_name' => $package->customer_name,
                'customer_phone' => $package->customer_phone,
                'delivery_address' => $package->delivery_address,
                'delivery_latitude' => $package->delivery_latitude,
                'delivery_longitude' => $package->delivery_longitude,
                'payment_type' => $package->payment_type,
                'amount' => (float) $package->amount,
                'package_image' => $package->package_image,
                'package_description' => $package->package_description,
                'tracking_code' => $package->tracking_code,
                'status' => $package->status,
                'is_draft' => $package->is_draft,
                'registered_at' => $package->registered_at ? $package->registered_at->toIso8601String() : null,
                'created_at' => $package->created_at->toIso8601String(),
                'updated_at' => $package->updated_at->toIso8601String(),
            ];
            
            return response()->json([
                'message' => 'Draft package updated successfully',
                'package' => $packageData,
            ], 200, [
                'Content-Type' => 'application/json',
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422, [
                'Content-Type' => 'application/json',
            ]);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'message' => 'Draft package not found',
                'error' => 'The specified draft package does not exist or does not belong to you.',
            ], 404, [
                'Content-Type' => 'application/json',
            ]);
        } catch (\Throwable $e) {
            Log::error('Error updating draft package', [
                'package_id' => $id,
                'error' => $e->getMessage(),
            ]);
            
            return response()->json([
                'message' => 'An error occurred while updating the draft',
                'error' => $e->getMessage(),
            ], 500, [
                'Content-Type' => 'application/json',
            ]);
        }
    }
}
