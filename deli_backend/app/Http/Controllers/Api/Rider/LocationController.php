<?php

namespace App\Http\Controllers\Api\Rider;

use App\Http\Controllers\Controller;
use App\Models\Rider;
use App\Models\RiderLocation;
use App\Events\RiderLocationUpdated;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class LocationController extends Controller
{
    public function update(Request $request)
    {
        try {
            $request->validate([
                'latitude' => 'required|numeric',
                'longitude' => 'required|numeric',
                'speed' => 'nullable|numeric',
                'heading' => 'nullable|numeric',
                'package_id' => 'nullable|exists:packages,id',
            ]);

            $rider = $request->user()->rider;

            if (!$rider) {
                return response()->json([
                    'message' => 'Rider profile not found',
                ], 404);
            }

            // Update rider's current location
            $rider->current_latitude = $request->latitude;
            $rider->current_longitude = $request->longitude;
            $rider->last_location_update = now();
            
            // Set rider status to 'available' if they're offline (they're using the app)
            if ($rider->status === 'offline') {
                $rider->status = 'available';
            }
            
            $rider->save();

            // Store location history (don't fail if this fails)
            try {
                RiderLocation::create([
                    'rider_id' => $rider->id,
                    'package_id' => $request->package_id,
                    'latitude' => $request->latitude,
                    'longitude' => $request->longitude,
                    'speed' => $request->speed,
                    'heading' => $request->heading,
                    'created_at' => now(),
                ]);
            } catch (\Exception $e) {
                // Log but don't fail - location history is optional
                \Illuminate\Support\Facades\Log::warning('Failed to save location history', [
                    'rider_id' => $rider->id,
                    'error' => $e->getMessage(),
                ]);
            }

            // Broadcast location update via WebSocket (don't fail if this fails)
            try {
                event(new RiderLocationUpdated(
                    $rider->id,
                    $request->latitude,
                    $request->longitude,
                    $request->package_id
                ));
            } catch (\Exception $e) {
                // Log but don't fail - WebSocket is optional
                \Illuminate\Support\Facades\Log::warning('Failed to broadcast location update', [
                    'rider_id' => $rider->id,
                    'error' => $e->getMessage(),
                ]);
            }

            // Send location update to Go WebSocket server (don't fail if this fails)
            try {
                $this->sendToGoServer(
                    $rider->id,
                    $request->latitude,
                    $request->longitude,
                    $request->package_id
                );
            } catch (\Exception $e) {
                // Log but don't fail - Go server is optional
                \Illuminate\Support\Facades\Log::warning('Failed to send location to Go server', [
                    'rider_id' => $rider->id,
                    'error' => $e->getMessage(),
                ]);
            }

            return response()->json([
                'message' => 'Location updated successfully',
                'location' => [
                    'latitude' => $rider->current_latitude,
                    'longitude' => $rider->current_longitude,
                    'last_update' => $rider->last_location_update,
                ],
            ])->header('Content-Type', 'application/json');
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422)->header('Content-Type', 'application/json');
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Location update failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            return response()->json([
                'message' => 'Failed to update location',
                'error' => $e->getMessage(),
            ], 500)->header('Content-Type', 'application/json');
        }
    }

    public function current(Request $request)
    {
        $rider = $request->user()->rider;

        return response()->json([
            'location' => [
                'latitude' => $rider->current_latitude,
                'longitude' => $rider->current_longitude,
                'last_update' => $rider->last_location_update,
            ],
        ]);
    }

    /**
     * Store location update from Node.js server (for database history)
     * This endpoint is called by the Node.js location tracker server
     * No authentication required - Node.js server is trusted
     */
    public function store(Request $request)
    {
        try {
            $sharedSecret = env('TRACKER_SHARED_SECRET');
            if ($sharedSecret && $request->header('X-Tracker-Secret') !== $sharedSecret) {
                return response()->json([
                    'message' => 'Unauthorized tracker request',
                ], 401);
            }

            $request->validate([
                'rider_id' => 'required|exists:riders,id',
                'latitude' => 'required|numeric',
                'longitude' => 'required|numeric',
                'package_id' => 'nullable|exists:packages,id',
                'speed' => 'nullable|numeric',
                'heading' => 'nullable|numeric',
            ]);

            $rider = Rider::findOrFail($request->rider_id);

            // Update rider's current location
            $rider->current_latitude = $request->latitude;
            $rider->current_longitude = $request->longitude;
            $rider->last_location_update = now();
            
            // Set rider status to 'available' if they're offline
            if ($rider->status === 'offline') {
                $rider->status = 'available';
            }
            
            $rider->save();

            // Store location history (optional, don't fail if this fails)
            try {
                RiderLocation::create([
                    'rider_id' => $rider->id,
                    'package_id' => $request->package_id,
                    'latitude' => $request->latitude,
                    'longitude' => $request->longitude,
                    'speed' => $request->speed,
                    'heading' => $request->heading,
                    'created_at' => now(),
                ]);
            } catch (\Exception $e) {
                // Log but don't fail - location history is optional
                \Illuminate\Support\Facades\Log::warning('Failed to save location history', [
                    'rider_id' => $rider->id,
                    'error' => $e->getMessage(),
                ]);
            }

            return response()->json([
                'message' => 'Location stored successfully',
            ], 200);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Location store failed', [
                'error' => $e->getMessage(),
            ]);
            
            return response()->json([
                'message' => 'Failed to store location',
            ], 500);
        }
    }

    /**
     * Send location to Go WebSocket server (best-effort).
     * Guarded by env so missing config won't break location updates.
     */
    private function sendToGoServer(int $riderId, float $latitude, float $longitude, $packageId = null): void
    {
        $goEndpoint = env('GO_WS_LOCATION_URL');
        $goToken = env('GO_WS_TOKEN');

        if (!$goEndpoint) {
            // Not configured; skip silently.
            return;
        }

        Http::timeout(3)
            ->withToken($goToken)
            ->post($goEndpoint, [
                'rider_id' => $riderId,
                'latitude' => $latitude,
                'longitude' => $longitude,
                'package_id' => $packageId,
                'sent_at' => now()->toIso8601String(),
            ]);
    }
}
