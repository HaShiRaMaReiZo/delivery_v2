<?php

namespace App\Http\Controllers\Api\Office;

use App\Http\Controllers\Controller;
use App\Models\Package;
use App\Models\PackageStatusHistory;
use App\Models\RiderAssignment;
use App\Events\PackageStatusChanged;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class PackageController extends Controller
{
    public function index(Request $request)
    {
        $query = Package::with(['merchant', 'currentRider', 'statusHistory']);

        // Filters
        if ($request->has('merchant_id')) {
            $query->where('merchant_id', $request->merchant_id);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('tracking_code')) {
            $query->where('tracking_code', $request->tracking_code);
        }

        if ($request->has('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->has('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $packages = $query->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json($packages);
    }

    public function show($id)
    {
        $package = Package::with(['merchant', 'currentRider', 'statusHistory', 'assignments', 'deliveryProof', 'codCollection'])
            ->findOrFail($id);

        return response()->json($package);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:arrived_at_office,assigned_to_rider,return_to_office,returned_to_merchant,cancelled',
            'notes' => 'nullable|string',
        ]);

        $package = Package::findOrFail($id);

        $oldStatus = $package->status;
        $newStatus = $request->status;

        // Update package status
        $package->status = $newStatus;
        $package->delivery_notes = $request->notes;
        $package->save();

        // Log status history
        PackageStatusHistory::create([
            'package_id' => $package->id,
            'status' => $newStatus,
            'changed_by_user_id' => $request->user()->id,
            'changed_by_type' => 'office',
            'notes' => $request->notes,
            'created_at' => now(),
        ]);

        // Broadcast status change via WebSocket
        event(new PackageStatusChanged($package->id, $newStatus, $package->merchant_id));

        return response()->json([
            'message' => 'Status updated successfully',
            'package' => $package->load(['merchant', 'currentRider', 'statusHistory']),
        ]);
    }

    public function assign(Request $request, $id)
    {
        try {
            Log::info('assign: Starting', [
                'package_id' => $id,
                'rider_id' => $request->rider_id,
                'user_id' => $request->user()->id,
            ]);

            // Clear any previous output
            if (ob_get_level()) {
                ob_clean();
            }

            $request->validate([
                'rider_id' => 'required|exists:riders,id',
            ]);

            Log::info('assign: Validation passed');

            $package = Package::findOrFail($id);
            $rider = \App\Models\Rider::findOrFail($request->rider_id);

            Log::info('assign: Package and rider found', [
                'package_status' => $package->status,
                'rider_name' => $rider->name,
            ]);

        // Determine assignment type based on current status
        // Delivery assignments: packages that are 'arrived_at_office' (ready to be assigned for delivery)
        // Pickup assignments: packages that are 'registered' (need to be picked up from merchant)
        $isDeliveryAssignment = $package->status === 'arrived_at_office';
        $assignmentType = $isDeliveryAssignment ? 'delivery' : 'pickup';
        
        // For delivery assignment from office: set status to 'assigned_to_rider' 
        // (rider needs to receive package from office, then it becomes 'ready_for_delivery')
        // For pickup assignment: change status to 'assigned_to_rider' (rider picks up from merchant)
        $package->status = 'assigned_to_rider';
        
        // Update package
        $package->current_rider_id = $rider->id;
        $package->assigned_at = now();
        $package->save();

        // Create assignment record
        RiderAssignment::create([
            'package_id' => $package->id,
            'rider_id' => $rider->id,
            'assigned_by_user_id' => $request->user()->id,
            'assigned_at' => now(),
            'status' => 'assigned',
        ]);

        // Log status history
        $statusNote = $isDeliveryAssignment 
            ? "Assigned to rider {$rider->name} for delivery"
            : "Assigned to rider {$rider->name} for pickup";
            
        PackageStatusHistory::create([
            'package_id' => $package->id,
            'status' => $package->status, // Use current status (picked_up for delivery, assigned_to_rider for pickup)
            'changed_by_user_id' => $request->user()->id,
            'changed_by_type' => 'office',
            'notes' => $statusNote,
            'created_at' => now(),
        ]);

        // Broadcast status change via WebSocket (wrap in try-catch to prevent breaking response)
        try {
            event(new PackageStatusChanged($package->id, $package->status, $package->merchant_id));
        } catch (\Exception $e) {
            Log::warning('Failed to broadcast package status change event', [
                'package_id' => $package->id,
                'error' => $e->getMessage(),
            ]);
        }

        $responseData = [
            'message' => $isDeliveryAssignment 
                ? 'Package assigned for delivery successfully'
                : 'Package assigned for pickup successfully',
            'assignment_type' => $assignmentType,
            'package' => $package->load(['merchant', 'currentRider', 'statusHistory']),
        ];

        Log::info('assign: Sending success response', [
            'assignment_type' => $assignmentType,
        ]);

        // Create and return JSON response
        return response()->json($responseData, 200, [
            'Content-Type' => 'application/json',
            'Cache-Control' => 'no-cache, no-store, must-revalidate',
            'X-Content-Type-Options' => 'nosniff',
        ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422)->header('Content-Type', 'application/json');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'message' => 'Package or rider not found',
                'error' => $e->getMessage(),
            ], 404)->header('Content-Type', 'application/json');
        } catch (\Exception $e) {
            // Ensure no output before error response
            if (ob_get_level()) {
                ob_end_clean();
            }
            
            Log::error('Error assigning rider to package', [
                'package_id' => $id,
                'rider_id' => $request->rider_id ?? null,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            return response()->json([
                'message' => 'Failed to assign rider',
                'error' => $e->getMessage(),
            ], 500, [
                'Content-Type' => 'application/json',
            ]);
        }
    }

    public function bulkAssign(Request $request)
    {
        $request->validate([
            'package_ids' => 'required|array',
            'package_ids.*' => 'exists:packages,id',
            'rider_id' => 'required|exists:riders,id',
        ]);

        $rider = \App\Models\Rider::findOrFail($request->rider_id);
        $assigned = [];
        $deliveryCount = 0;
        $pickupCount = 0;

        foreach ($request->package_ids as $packageId) {
            $package = Package::findOrFail($packageId);

            // Determine assignment type based on current status
            // Delivery assignments: packages that are 'arrived_at_office' (ready to be assigned for delivery)
            // Pickup assignments: packages that are 'registered' (need to be picked up from merchant)
            $isDeliveryAssignment = $package->status === 'arrived_at_office';
            
            // For delivery assignment from office: set status to 'assigned_to_rider'
            // (rider needs to receive package from office, then it becomes 'ready_for_delivery')
            // For pickup assignment: change status to 'assigned_to_rider' (rider picks up from merchant)
            $package->status = 'assigned_to_rider';
            
            // Update package
            $package->current_rider_id = $rider->id;
            $package->assigned_at = now();
            $package->save();

            // Create assignment record
            RiderAssignment::create([
                'package_id' => $package->id,
                'rider_id' => $rider->id,
                'assigned_by_user_id' => $request->user()->id,
                'assigned_at' => now(),
                'status' => 'assigned',
            ]);

            // Log status history
            $statusNote = $isDeliveryAssignment 
                ? "Bulk assigned to rider {$rider->name} for delivery"
                : "Bulk assigned to rider {$rider->name} for pickup";
                
            PackageStatusHistory::create([
                'package_id' => $package->id,
                'status' => $package->status,
                'changed_by_user_id' => $request->user()->id,
                'changed_by_type' => 'office',
                'notes' => $statusNote,
                'created_at' => now(),
            ]);

            // Broadcast status change via WebSocket
            event(new PackageStatusChanged($package->id, $package->status, $package->merchant_id));

            if ($isDeliveryAssignment) {
                $deliveryCount++;
            } else {
                $pickupCount++;
            }
            
            $assigned[] = $package->id;
        }

        return response()->json([
            'message' => 'Packages assigned successfully',
            'assigned_count' => count($assigned),
            'pickup_count' => $pickupCount,
            'delivery_count' => $deliveryCount,
            'assigned_ids' => $assigned,
        ]);
    }

    public function assignPickupByMerchant(Request $request, $merchantId)
    {
        try {
            Log::info('assignPickupByMerchant: Starting', [
                'merchant_id' => $merchantId,
                'rider_id' => $request->rider_id,
                'user_id' => $request->user()->id,
            ]);

            $request->validate([
                'rider_id' => 'required|exists:riders,id',
            ]);

            Log::info('assignPickupByMerchant: Validation passed');

            $rider = \App\Models\Rider::findOrFail($request->rider_id);
            $merchant = \App\Models\Merchant::findOrFail($merchantId);

            Log::info('assignPickupByMerchant: Rider and merchant found', [
                'rider_name' => $rider->name,
                'merchant_name' => $merchant->business_name,
            ]);

            // Get all registered packages from this merchant
            $packages = Package::where('merchant_id', $merchantId)
                ->where('status', 'registered')
                ->get();

            Log::info('assignPickupByMerchant: Found packages', [
                'count' => $packages->count(),
                'package_ids' => $packages->pluck('id')->toArray(),
            ]);

            if ($packages->isEmpty()) {
                Log::warning('assignPickupByMerchant: No registered packages found');
                return response()->json([
                    'message' => 'No registered packages found for this merchant',
                    'assigned_count' => 0,
                ], 404)->header('Content-Type', 'application/json');
            }

            $assigned = [];

            DB::beginTransaction();
            try {
                Log::info('assignPickupByMerchant: Starting transaction');
                foreach ($packages as $package) {
                    Log::info('assignPickupByMerchant: Processing package', [
                        'package_id' => $package->id,
                        'tracking_code' => $package->tracking_code,
                    ]);

                    // Update package - assign for pickup
                    $package->current_rider_id = $rider->id;
                    $package->status = 'assigned_to_rider';
                    $package->assigned_at = now();
                    $package->save();

                    Log::info('assignPickupByMerchant: Package updated', [
                        'package_id' => $package->id,
                        'status' => $package->status,
                        'rider_id' => $package->current_rider_id,
                    ]);

                    // Create assignment record
                    RiderAssignment::create([
                        'package_id' => $package->id,
                        'rider_id' => $rider->id,
                        'assigned_by_user_id' => $request->user()->id,
                        'assigned_at' => now(),
                        'status' => 'assigned',
                    ]);

                    // Log status history
                    PackageStatusHistory::create([
                        'package_id' => $package->id,
                        'status' => 'assigned_to_rider',
                        'changed_by_user_id' => $request->user()->id,
                        'changed_by_type' => 'office',
                        'notes' => "Assigned to rider {$rider->name} for pickup from merchant {$merchant->business_name}",
                        'created_at' => now(),
                    ]);

                    // Broadcast status change via WebSocket (wrap in try-catch to prevent breaking response)
                    try {
                        event(new PackageStatusChanged($package->id, 'assigned_to_rider', $package->merchant_id));
                    } catch (\Exception $eventException) {
                        Log::warning('Failed to broadcast package status change event', [
                            'package_id' => $package->id,
                            'error' => $eventException->getMessage(),
                        ]);
                    }

                    $assigned[] = $package->id;
                }
                DB::commit();
                Log::info('assignPickupByMerchant: Transaction committed', [
                    'assigned_count' => count($assigned),
                ]);
            } catch (\Exception $e) {
                DB::rollBack();
                Log::error('assignPickupByMerchant: Transaction failed', [
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString(),
                ]);
                throw $e;
            }

            // Build response data
            $responseData = [
                'message' => 'Rider assigned for pickup from merchant successfully',
                'merchant' => [
                    'id' => $merchant->id,
                    'business_name' => $merchant->business_name,
                    'business_address' => $merchant->business_address,
                ],
                'rider' => [
                    'id' => $rider->id,
                    'name' => $rider->name,
                ],
                'assigned_count' => count($assigned),
                'assigned_package_ids' => $assigned,
            ];

            Log::info('assignPickupByMerchant: Sending success response', [
                'assigned_count' => count($assigned),
            ]);

            // Create response - ensure it's properly formatted for Render
            // Use json_encode directly to ensure clean JSON output
            $jsonContent = json_encode($responseData, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            
            Log::info('assignPickupByMerchant: Response JSON created', [
                'json_length' => strlen($jsonContent),
                'json_preview' => substr($jsonContent, 0, 200),
            ]);
            
            // Return response with explicit content
            return response($jsonContent, 200, [
                'Content-Type' => 'application/json; charset=utf-8',
                'Content-Length' => strlen($jsonContent),
                'Cache-Control' => 'no-cache, no-store, must-revalidate',
                'X-Content-Type-Options' => 'nosniff',
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422)->header('Content-Type', 'application/json');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'message' => 'Rider or merchant not found',
                'error' => $e->getMessage(),
            ], 404)->header('Content-Type', 'application/json');
        } catch (\Exception $e) {
            Log::error('Error assigning pickup by merchant', [
                'merchant_id' => $merchantId,
                'rider_id' => $request->rider_id ?? null,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            return response()->json([
                'message' => 'Failed to assign rider for pickup',
                'error' => $e->getMessage(),
            ], 500)->header('Content-Type', 'application/json');
        }
    }

    public function arrived(Request $request)
    {
        $query = Package::where('status', 'registered')
            ->with(['merchant'])
            ->orderBy('created_at', 'desc');

        if ($request->has('merchant_id')) {
            $query->where('merchant_id', $request->merchant_id);
        }

        $packages = $query->paginate(20);

        return response()->json($packages);
    }
}
