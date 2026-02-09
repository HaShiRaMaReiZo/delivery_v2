<?php

namespace App\Http\Controllers\Api\Rider;

use App\Http\Controllers\Controller;
use App\Models\Package;
use App\Models\PackageStatusHistory;
use App\Models\RiderAssignment;
use App\Models\DeliveryProof;
use App\Models\CodCollection;
use App\Events\PackageStatusChanged;
use Illuminate\Http\Request;

class PackageController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $rider = $user->rider;
        
        if (!$rider) {
            return response()->json([
                'message' => 'Rider profile not found'
            ], 404);
        }
        
        // Check if we need to include delivered packages
        $includeDelivered = $request->query('include_delivered', 'false') === 'true' || $request->query('include_delivered') === true;
        
        if ($includeDelivered) {
            // Return all packages including delivered ones
            $packages = Package::where('current_rider_id', $rider->id)
                ->whereIn('status', [
                    'assigned_to_rider',  // For pickup from merchant OR assigned for delivery (need to receive from office)
                    'picked_up',          // Picked up from merchant (legacy, for backward compatibility)
                    'ready_for_delivery', // Received from office, ready to start delivery
                    'on_the_way',        // Currently being delivered
                    'delivered',         // Delivered packages
                    'cancelled'          // Cancelled, rider needs to return to office
                ])
                ->with(['merchant', 'statusHistory.changedBy'])
                ->orderBy('created_at', 'desc')
                ->get();
        } else {
            // Only return packages that are actively assigned to the rider
            // Exclude completed/delivered/returned packages
            // Note: contact_failed packages are automatically reassigned (status becomes arrived_at_office)
            // Only cancelled packages need to be returned to office
            $packages = Package::where('current_rider_id', $rider->id)
                ->whereIn('status', [
                    'assigned_to_rider',  // For pickup from merchant OR assigned for delivery (need to receive from office)
                    'picked_up',          // Picked up from merchant (legacy, for backward compatibility)
                    'ready_for_delivery', // Received from office, ready to start delivery
                    'on_the_way',        // Currently being delivered
                    'cancelled'          // Cancelled, rider needs to return to office
                ])
                ->with(['merchant', 'statusHistory.changedBy'])
                ->orderBy('created_at', 'desc')
                ->get();
        }

        return response()->json($packages);
    }

    public function show(Request $request, $id)
    {
        $user = $request->user();
        $rider = $user->rider;
        
        if (!$rider) {
            return response()->json([
                'message' => 'Rider profile not found'
            ], 404);
        }
        
        $package = Package::where('current_rider_id', $rider->id)
            ->with(['merchant', 'statusHistory.changedBy', 'deliveryProof', 'codCollection'])
            ->findOrFail($id);

        return response()->json($package);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:picked_up,ready_for_delivery,on_the_way,delivered,contact_failed,return_to_office,cancelled',
            'notes' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
        ]);

        $rider = $request->user()->rider;
        
        $package = Package::where('current_rider_id', $rider->id)
            ->findOrFail($id);

        $oldStatus = $package->status;
        $newStatus = $request->status;

        // Update package status
        $package->status = $newStatus;
        
        // Update timestamps based on status
        if ($newStatus === 'picked_up' && !$package->picked_up_at) {
            $package->picked_up_at = now();
        } elseif ($newStatus === 'delivered' && !$package->delivered_at) {
            $package->delivered_at = now();
        }

        // When returning to office, clear the rider assignment
        // This removes the package from the rider's active assignments
        if ($newStatus === 'return_to_office') {
            $package->current_rider_id = null;
        }

        $package->delivery_notes = $request->notes;
        $package->save();

        // Log status history
        PackageStatusHistory::create([
            'package_id' => $package->id,
            'status' => $newStatus,
            'changed_by_user_id' => $request->user()->id,
            'changed_by_type' => 'rider',
            'notes' => $request->notes,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'created_at' => now(),
        ]);

        // Broadcast status change via WebSocket
        event(new PackageStatusChanged($package->id, $newStatus, $package->merchant_id));

        return response()->json([
            'message' => 'Status updated successfully',
            'package' => $package->load(['merchant', 'statusHistory']),
        ]);
    }

    public function receiveFromOffice(Request $request, $id)
    {
        $request->validate([
            'notes' => 'nullable|string',
        ]);

        $rider = $request->user()->rider;
        
        $package = Package::where('current_rider_id', $rider->id)
            ->where('status', 'assigned_to_rider')
            ->findOrFail($id);

        // Check if this is a delivery assignment (previous status was arrived_at_office)
        // Get the most recent status history entry
        $lastStatusHistory = \App\Models\PackageStatusHistory::where('package_id', $package->id)
            ->orderBy('created_at', 'desc')
            ->skip(1) // Skip the current assigned_to_rider entry
            ->first();
        
        $isDeliveryAssignment = $lastStatusHistory && $lastStatusHistory->status === 'arrived_at_office';

        if (!$isDeliveryAssignment) {
            return response()->json([
                'message' => 'This package is not assigned for delivery from office',
            ], 400);
        }

        // Update package status to ready_for_delivery
        $package->status = 'ready_for_delivery';
        $package->save();

        // Log status history
        PackageStatusHistory::create([
            'package_id' => $package->id,
            'status' => 'ready_for_delivery',
            'changed_by_user_id' => $request->user()->id,
            'changed_by_type' => 'rider',
            'notes' => $request->notes ?? 'Received package from office',
            'created_at' => now(),
        ]);

        // Broadcast status change via WebSocket
        event(new PackageStatusChanged($package->id, 'ready_for_delivery', $package->merchant_id));

        return response()->json([
            'message' => 'Package received from office successfully',
            'package' => $package->load(['merchant', 'statusHistory']),
        ]);
    }

    public function startDelivery(Request $request, $id)
    {
        $rider = $request->user()->rider;
        
        $package = Package::where('current_rider_id', $rider->id)
            ->whereIn('status', ['ready_for_delivery', 'picked_up']) // Allow both ready_for_delivery and picked_up (legacy)
            ->findOrFail($id);

        // Update status to on_the_way
        $package->status = 'on_the_way';
        $package->save();

        // Log status history
        PackageStatusHistory::create([
            'package_id' => $package->id,
            'status' => 'on_the_way',
            'changed_by_user_id' => $request->user()->id,
            'changed_by_type' => 'rider',
            'notes' => 'Rider started delivery',
            'created_at' => now(),
        ]);

        // Update rider status to busy
        $rider->status = 'busy';
        $rider->save();

        // Broadcast status change via WebSocket
        event(new PackageStatusChanged($package->id, 'on_the_way', $package->merchant_id));

        return response()->json([
            'message' => 'Delivery started successfully',
            'package' => $package->load(['merchant', 'statusHistory']),
        ]);
    }

    public function contactCustomer(Request $request, $id)
    {
        $request->validate([
            'contact_result' => 'required|in:success,failed',
            'notes' => 'nullable|string',
        ]);

        $rider = $request->user()->rider;
        
        $package = Package::where('current_rider_id', $rider->id)
            ->findOrFail($id);

        if ($request->contact_result === 'failed') {
            // Change status to contact_failed and clear rider assignment for next day reassignment
            $package->status = 'contact_failed';
            $package->current_rider_id = null; // Clear rider assignment so office can reassign for next day
            $package->delivery_notes = $request->notes ?? 'Customer contact failed - ready for next day reassignment';
            $package->save();

            // Log status history
            PackageStatusHistory::create([
                'package_id' => $package->id,
                'status' => 'contact_failed',
                'changed_by_user_id' => $request->user()->id,
                'changed_by_type' => 'rider',
                'notes' => $request->notes ?? 'Customer contact failed - ready for next day reassignment',
                'created_at' => now(),
            ]);

            // Broadcast status change via WebSocket
            event(new PackageStatusChanged($package->id, 'contact_failed', $package->merchant_id));
        } else if ($request->contact_result === 'success') {
            // Log successful contact (status remains unchanged)
            PackageStatusHistory::create([
                'package_id' => $package->id,
                'status' => $package->status, // Keep current status
                'changed_by_user_id' => $request->user()->id,
                'changed_by_type' => 'rider',
                'notes' => $request->notes ?? 'Customer contact successful',
                'created_at' => now(),
            ]);
        }

        return response()->json([
            'message' => 'Contact result recorded',
            'package' => $package->load(['merchant', 'statusHistory']),
        ]);
    }

    public function uploadProof(Request $request, $id)
    {
        $request->validate([
            'proof_type' => 'nullable|in:photo,signature',
            'proof_data' => 'nullable',
            'delivery_latitude' => 'nullable|numeric',
            'delivery_longitude' => 'nullable|numeric',
            'delivered_to_name' => 'nullable|string',
            'delivered_to_phone' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        $rider = $request->user()->rider;
        
        $package = Package::where('current_rider_id', $rider->id)
            ->findOrFail($id);

        // Handle proof upload (optional)
        if ($request->has('proof_type') && $request->has('proof_data')) {
        $proofData = $request->proof_data;
        if ($request->proof_type === 'photo' && $request->hasFile('proof_data')) {
            $proofData = $request->file('proof_data')->store('delivery_proofs', 'public');
        }

        DeliveryProof::create([
            'package_id' => $package->id,
            'rider_id' => $rider->id,
            'proof_type' => $request->proof_type,
            'proof_data' => $proofData,
            'delivery_latitude' => $request->delivery_latitude,
            'delivery_longitude' => $request->delivery_longitude,
            'delivered_to_name' => $request->delivered_to_name,
            'delivered_to_phone' => $request->delivered_to_phone,
            'notes' => $request->notes,
            'created_at' => now(),
        ]);
        }

        // Update package status to delivered
        $package->status = 'delivered';
        if (!$package->delivered_at) {
            $package->delivered_at = now();
        }
        $package->save();

        // Get delivery location (from request or rider's current location)
        $latitude = $request->delivery_latitude ?? $rider->current_latitude;
        $longitude = $request->delivery_longitude ?? $rider->current_longitude;

        // Log status history with delivery location
        PackageStatusHistory::create([
            'package_id' => $package->id,
            'status' => 'delivered',
            'changed_by_user_id' => $request->user()->id,
            'changed_by_type' => 'rider',
            'notes' => $request->notes ?? 'Package delivered with proof',
            'latitude' => $latitude,
            'longitude' => $longitude,
            'created_at' => now(),
        ]);

        // Broadcast status change via WebSocket
        event(new PackageStatusChanged($package->id, 'delivered', $package->merchant_id));

        return response()->json([
            'message' => 'Delivery proof uploaded successfully and package marked as delivered',
            'package' => $package->load(['merchant', 'statusHistory']),
        ]);
    }

    public function collectCod(Request $request, $id)
    {
        $request->validate([
            'amount' => 'required|numeric|min:0',
            'collection_proof' => 'nullable|image|max:2048',
        ]);

        $rider = $request->user()->rider;
        
        $package = Package::where('current_rider_id', $rider->id)
            ->findOrFail($id);

        if ($package->payment_type !== 'cod') {
            return response()->json([
                'message' => 'Package is not COD',
            ], 400);
        }

        // Handle collection proof upload
        $collectionProof = null;
        if ($request->hasFile('collection_proof')) {
            $collectionProof = $request->file('collection_proof')->store('cod_proofs', 'public');
        }

        // Get rider's current location for delivery location
        $latitude = $rider->current_latitude;
        $longitude = $rider->current_longitude;

        // Create COD collection record
        CodCollection::create([
            'package_id' => $package->id,
            'rider_id' => $rider->id,
            'amount' => $request->amount,
            'collected_at' => now(),
            'collection_proof' => $collectionProof,
            'status' => 'collected',
        ]);

        // Update package status to delivered
        $package->status = 'delivered';
        if (!$package->delivered_at) {
            $package->delivered_at = now();
        }
        $package->save();

        // Log status history with delivery location
        PackageStatusHistory::create([
            'package_id' => $package->id,
            'status' => 'delivered',
            'changed_by_user_id' => $request->user()->id,
            'changed_by_type' => 'rider',
            'notes' => 'COD collected and package delivered',
            'latitude' => $latitude,
            'longitude' => $longitude,
            'created_at' => now(),
        ]);

        // Broadcast status change via WebSocket
        event(new PackageStatusChanged($package->id, 'delivered', $package->merchant_id));

        return response()->json([
            'message' => 'COD collected successfully and package marked as delivered',
            'package' => $package->load(['merchant', 'statusHistory']),
        ]);
    }

    public function confirmPickupByMerchant(Request $request, $merchantId)
    {
        $request->validate([
            'notes' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
        ]);

        $rider = $request->user()->rider;
        $merchant = \App\Models\Merchant::findOrFail($merchantId);

        // Get all packages from this merchant that are assigned to this rider for pickup
        // Status should be 'assigned_to_rider' (pickup assignment)
        $packages = Package::where('merchant_id', $merchantId)
            ->where('current_rider_id', $rider->id)
            ->where('status', 'assigned_to_rider')
            ->get();

        if ($packages->isEmpty()) {
            return response()->json([
                'message' => 'No packages assigned for pickup from this merchant',
                'confirmed_count' => 0,
            ], 404);
        }

        $confirmed = [];

        foreach ($packages as $package) {
            // Update package status to picked_up
            $package->status = 'picked_up';
            if (!$package->picked_up_at) {
                $package->picked_up_at = now();
            }
            if ($request->notes) {
                $package->delivery_notes = $request->notes;
            }
            $package->save();

            // Update assignment record
            $assignment = RiderAssignment::where('package_id', $package->id)
                ->where('rider_id', $rider->id)
                ->where('status', 'assigned')
                ->latest()
                ->first();
            
            if ($assignment) {
                $assignment->status = 'picked_up';
                $assignment->save();
            }

            // Log status history
            PackageStatusHistory::create([
                'package_id' => $package->id,
                'status' => 'picked_up',
                'changed_by_user_id' => $request->user()->id,
                'changed_by_type' => 'rider',
                'notes' => $request->notes ?? "Pickup confirmed from merchant {$merchant->business_name}",
                'latitude' => $request->latitude,
                'longitude' => $request->longitude,
                'created_at' => now(),
            ]);

            // Broadcast status change via WebSocket
            event(new PackageStatusChanged($package->id, 'picked_up', $package->merchant_id));

            $confirmed[] = $package->id;
        }

        return response()->json([
            'message' => 'Pickup confirmed successfully',
            'merchant' => [
                'id' => $merchant->id,
                'business_name' => $merchant->business_name,
                'business_address' => $merchant->business_address,
            ],
            'confirmed_count' => count($confirmed),
            'confirmed_package_ids' => $confirmed,
        ]);
    }

    /**
     * Get delivered packages for the current month only
     * This endpoint returns packages that were delivered in the current month
     * (e.g., if it's January, only January deliveries; if February, only February, etc.)
     */
    /**
     * Get delivery history for current month
     * Route: GET /api/rider/packages/{rider_id}/history
     */
    public function history(Request $request, $rider_id)
    {
        $user = $request->user();
        $rider = $user->rider;
        
        if (!$rider) {
            return response()->json([
                'message' => 'Rider profile not found'
            ], 404);
        }
        
        // Validate that the rider_id in the path matches the authenticated user's rider
        // Use relationship ID (works even if rider_id column is null)
        if ($rider->id != $rider_id) {
            return response()->json([
                'message' => 'Unauthorized: You can only access your own history'
            ], 403);
        }
        
        // Get current month start and end dates
        $now = now();
        $startOfMonth = $now->copy()->startOfMonth();
        $endOfMonth = $now->copy()->endOfMonth();
        
        // Get delivered packages for current month only
        $packages = Package::where('current_rider_id', $rider_id)
            ->where('status', 'delivered')
            ->whereNotNull('delivered_at')
            ->whereBetween('delivered_at', [$startOfMonth, $endOfMonth])
            ->with(['merchant', 'statusHistory.changedBy'])
            ->orderBy('delivered_at', 'desc')
            ->get();
        
        return response()->json($packages);
    }
}
