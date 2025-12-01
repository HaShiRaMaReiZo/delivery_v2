<?php

namespace App\Http\Controllers\Api\Office;

use App\Http\Controllers\Controller;
use App\Models\Rider;
use Illuminate\Http\Request;

class RiderController extends Controller
{
    public function index(Request $request)
    {
        $query = Rider::with(['user', 'zone']);

        // Filters
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('zone_id')) {
            $query->where('zone_id', $request->zone_id);
        }

        $riders = $query->orderBy('name', 'asc')->get();

        // Add package count for each rider
        $riders->map(function ($rider) {
            $rider->package_count = \App\Models\Package::where('current_rider_id', $rider->id)
                ->whereIn('status', ['assigned_to_rider', 'picked_up', 'on_the_way'])
                ->count();
            return $rider;
        });

        return response()->json($riders);
    }

    public function show($id)
    {
        $rider = Rider::with(['user', 'zone', 'packages' => function ($query) {
            $query->whereIn('status', ['assigned_to_rider', 'picked_up', 'on_the_way']);
        }])->findOrFail($id);

        return response()->json($rider);
    }

    public function locations(Request $request)
    {
        try {
            // Clear any output buffers to ensure clean JSON response
            while (ob_get_level()) {
                ob_end_clean();
            }
            
            // Get all active riders with their current locations
            // Only show riders who have sent at least one location update
            $riders = Rider::whereNotNull('current_latitude')
                ->whereNotNull('current_longitude')
                ->where('status', '!=', 'offline')
                ->select('id', 'name', 'phone', 'status', 'current_latitude', 'current_longitude', 'last_location_update')
                ->get();

            // Get package counts in a single query to avoid N+1 problem
            $riderIds = $riders->pluck('id')->toArray();
            $packageCounts = [];
            if (!empty($riderIds)) {
                $packageCounts = \App\Models\Package::whereIn('current_rider_id', $riderIds)
                    ->whereIn('status', ['assigned_to_rider', 'picked_up', 'on_the_way'])
                    ->groupBy('current_rider_id')
                    ->selectRaw('current_rider_id, count(*) as count')
                    ->pluck('count', 'current_rider_id')
                    ->toArray();
            }

            $locations = $riders->map(function ($rider) use ($packageCounts) {
                return [
                    'rider_id' => $rider->id,
                    'name' => $rider->name,
                    'phone' => $rider->phone,
                    'status' => $rider->status,
                    'latitude' => (float) $rider->current_latitude,
                    'longitude' => (float) $rider->current_longitude,
                    'last_location_update' => $rider->last_location_update ? $rider->last_location_update->toIso8601String() : null,
                    'package_count' => $packageCounts[$rider->id] ?? 0,
                ];
            })->filter(function ($rider) {
                // Only return riders that have actual location data (for map display)
                return $rider['latitude'] !== null && $rider['longitude'] !== null;
            })->values();

            // Return clean JSON response
            return response()->json([
                'riders' => $locations,
            ], 200, [
                'Content-Type' => 'application/json; charset=utf-8',
                'Cache-Control' => 'no-cache, no-store, must-revalidate',
            ]);
        } catch (\Exception $e) {
            // Clear output buffers on error
            while (ob_get_level()) {
                ob_end_clean();
            }
            
            \Illuminate\Support\Facades\Log::error('RiderController::locations error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            return response()->json([
                'riders' => [],
                'error' => 'Failed to load rider locations',
            ], 200, [
                'Content-Type' => 'application/json; charset=utf-8',
            ]);
        }
    }
}
