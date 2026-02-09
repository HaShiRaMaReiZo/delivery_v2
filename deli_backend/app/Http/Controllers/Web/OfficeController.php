<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Package;
use App\Models\Rider;
use App\Models\User;
use App\Models\Merchant;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class OfficeController extends Controller
{
    // Middleware is handled in routes/web.php
    // Role check is done in each method if needed

    public function dashboard()
    {
        // Verify user has office role (auth middleware already checked in routes)
        $user = auth()->user();
        $officeRoles = ['super_admin', 'office_manager', 'office_staff'];
        if (!in_array($user->role, $officeRoles)) {
            abort(403, 'Access denied');
        }
        
        $apiToken = $this->getApiToken();
        
        try {
            // Statistics
            $stats = [
                'total_packages' => Package::count(),
                'pending_packages' => Package::where('status', 'registered')->count(),
                'in_transit' => Package::whereIn('status', ['assigned_to_rider', 'picked_up', 'on_the_way'])->count(),
                'delivered_today' => Package::where('status', 'delivered')
                    ->whereDate('updated_at', today())
                    ->count(),
                'active_riders' => Rider::where('status', '!=', 'offline')->count(),
                'total_riders' => Rider::count(),
                'total_merchants' => Merchant::count(),
            ];

            // Recent packages - use optional relationships to avoid errors
            $recentPackages = Package::with(['merchant', 'currentRider'])
                ->orderBy('created_at', 'desc')
                ->limit(10)
                ->get();

            // Packages by status
            $packagesByStatus = Package::selectRaw('status, count(*) as count')
                ->groupBy('status')
                ->pluck('count', 'status')
                ->toArray();

            return view('office.dashboard', compact('stats', 'recentPackages', 'packagesByStatus', 'apiToken'));
        } catch (\Exception $e) {
            // Log the error and show a friendly message
            Log::error('Dashboard error: ' . $e->getMessage());
            return view('office.dashboard', [
                'stats' => [
                    'total_packages' => 0,
                    'pending_packages' => 0,
                    'in_transit' => 0,
                    'delivered_today' => 0,
                    'active_riders' => 0,
                    'total_riders' => 0,
                    'total_merchants' => 0,
                ],
                'recentPackages' => collect([]),
                'packagesByStatus' => [],
                'error' => 'Unable to load dashboard data. Please check database connection.',
            ]);
        }
    }

    public function packages(Request $request)
    {
        // Verify user has office role (auth middleware already checked in routes)
        $user = auth()->user();
        $officeRoles = ['super_admin', 'office_manager', 'office_staff'];
        if (!in_array($user->role, $officeRoles)) {
            abort(403, 'Access denied');
        }
        
        // Only load relationships needed for list view (not statusHistory - too heavy)
        // Show packages with all statuses including: registered, assigned_to_rider, picked_up, ready_for_delivery, contact_failed
        $query = Package::whereIn('status', [
            'registered',
            'arrived_at_office',
            'assigned_to_rider',
            'picked_up',
            'ready_for_delivery',
            'on_the_way',
            'delivered',
            'return_to_office',
            'returned_to_merchant',
            'cancelled',
            'contact_failed'
        ])
            ->with(['merchant:id,business_name', 'currentRider:id,name', 'statusHistory']);

        // Filters
        if ($request->has('merchant_id') && $request->merchant_id) {
            $query->where('merchant_id', $request->merchant_id);
        }

        if ($request->has('status') && $request->status) {
            $query->where('status', $request->status);
        }

        if ($request->has('tracking_code') && $request->tracking_code) {
            $query->where('tracking_code', 'like', '%' . $request->tracking_code . '%');
        }

        if ($request->has('date_from') && $request->date_from) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->has('date_to') && $request->date_to) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $packages = $query->orderBy('created_at', 'desc')->paginate(20);
        
        // Only select needed columns for dropdowns to improve performance
        $merchants = Merchant::select('id', 'business_name')->orderBy('business_name')->get();
        $riders = Rider::select('id', 'name', 'status')->orderBy('name')->get();

        $statuses = [
            'registered' => 'Registered',
            'arrived_at_office' => 'Arrived at Office',
            'assigned_to_rider' => 'Assigned to Rider',
            'picked_up' => 'Picked Up',
            'ready_for_delivery' => 'Ready for Delivery',
            'on_the_way' => 'On the Way',
            'delivered' => 'Delivered',
            'return_to_office' => 'Returned to Office',
            'returned_to_merchant' => 'Returned to Merchant',
            'cancelled' => 'Cancelled',
            'contact_failed' => 'Contact Failed',
        ];

        $apiToken = $this->getApiToken();
        return view('office.packages', compact('packages', 'merchants', 'riders', 'statuses', 'apiToken'));
    }

    public function registeredPackagesByMerchant(Request $request)
    {
        // Verify user has office role (auth middleware already checked in routes)
        $user = auth()->user();
        $officeRoles = ['super_admin', 'office_manager', 'office_staff'];
        if (!in_array($user->role, $officeRoles)) {
            abort(403, 'Access denied');
        }
        
        $apiToken = $this->getApiToken();
        
        // Get all registered packages grouped by merchant
        $packages = Package::where('status', 'registered')
            ->with(['merchant:id,business_name,business_address,business_phone', 'currentRider:id,name'])
            ->orderBy('created_at', 'desc')
            ->get();
        
        // Group packages by merchant
        $packagesByMerchant = $packages->groupBy('merchant_id');
        
        // Get all merchants with registered packages
        $merchants = Merchant::whereIn('id', $packagesByMerchant->keys())
            ->select('id', 'business_name', 'business_address', 'business_phone')
            ->orderBy('business_name')
            ->get();
        
        // Get all riders for assignment
        $riders = Rider::select('id', 'name', 'status')
            ->where('status', '!=', 'offline')
            ->orderBy('name')
            ->get();
        
        return view('office.registered_packages_by_merchant', compact('packagesByMerchant', 'merchants', 'riders', 'apiToken'));
    }

    public function pickedUpPackages(Request $request)
    {
        // Verify user has office role (auth middleware already checked in routes)
        $user = auth()->user();
        $officeRoles = ['super_admin', 'office_manager', 'office_staff'];
        if (!in_array($user->role, $officeRoles)) {
            abort(403, 'Access denied');
        }
        
        $apiToken = $this->getApiToken();
        
        // Get packages that are picked_up or arrived_at_office (grouped by merchant)
        $packages = Package::whereIn('status', ['picked_up', 'arrived_at_office'])
            ->with(['merchant:id,business_name,business_address,business_phone', 'currentRider:id,name'])
            ->orderBy('created_at', 'desc')
            ->get();
        
        // Group packages by merchant
        $packagesByMerchant = $packages->groupBy('merchant_id');
        
        // Get all merchants with picked up packages
        $merchants = Merchant::whereIn('id', $packagesByMerchant->keys())
            ->select('id', 'business_name', 'business_address', 'business_phone')
            ->orderBy('business_name')
            ->get();
        
        return view('office.picked_up_packages', compact('packagesByMerchant', 'merchants', 'apiToken'));
    }

    public function riders(Request $request)
    {
        // Only load necessary relationships with specific columns
        $query = Rider::with(['user:id,name,email', 'zone:id,name']);

        if ($request->has('status') && $request->status) {
            $query->where('status', $request->status);
        }

        $riders = $query->orderBy('name', 'asc')->get();

        // Get package counts in a single query to avoid N+1 problem
        $riderIds = $riders->pluck('id')->toArray();
        $packageCounts = Package::whereIn('current_rider_id', $riderIds)
            ->whereIn('status', ['assigned_to_rider', 'picked_up', 'on_the_way'])
            ->groupBy('current_rider_id')
            ->selectRaw('current_rider_id, count(*) as count')
            ->pluck('count', 'current_rider_id')
            ->toArray();

        // Add package count to each rider
        $riders->map(function ($rider) use ($packageCounts) {
            $rider->package_count = $packageCounts[$rider->id] ?? 0;
            return $rider;
        });

        $apiToken = $this->getApiToken();
        return view('office.riders', compact('riders', 'apiToken'));
    }

    public function map()
    {
        try {
            $user = auth()->user();
            if (!$user) {
                return redirect()->route('login')->with('error', 'Please login to access this page.');
            }
            
            $apiToken = $this->getApiToken();
            if (!$apiToken) {
                Log::error('Failed to get API token for user: ' . $user->id);
                return redirect()->back()->with('error', 'Failed to initialize. Please try again.');
            }
            
            return view('office.map', compact('apiToken', 'user'));
        } catch (\Exception $e) {
            Log::error('Error in map method: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            return redirect()->back()->with('error', 'An error occurred. Please try again.');
        }
    }

    public function showRegisterUser()
    {
        // Verify user has office role
        $user = auth()->user();
        $officeRoles = ['super_admin', 'office_manager', 'office_staff'];
        if (!in_array($user->role, $officeRoles)) {
            abort(403, 'Access denied');
        }

        return view('office.register_user');
    }

    public function registerUser(Request $request)
    {
        // Verify user has office role
        $user = auth()->user();
        $officeRoles = ['super_admin', 'office_manager', 'office_staff'];
        if (!in_array($user->role, $officeRoles)) {
            abort(403, 'Access denied');
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
            'phone' => 'nullable|string|max:20',
            'role' => 'required|in:merchant,rider',
        ]);

        if ($validator->fails()) {
            return redirect()->route('office.register_user')
                ->withErrors($validator)
                ->withInput();
        }

        // Additional validation based on role
        if ($request->role === 'merchant') {
            $validator = Validator::make($request->all(), [
                'business_name' => 'required|string|max:255',
                'business_address' => 'required|string',
                'business_phone' => 'required|string',
                'business_email' => 'required|email',
            ]);

            if ($validator->fails()) {
                return redirect()->route('office.register_user')
                    ->withErrors($validator)
                    ->withInput();
            }
        } elseif ($request->role === 'rider') {
            $validator = Validator::make($request->all(), [
                'vehicle_type' => 'required|in:bike,motorcycle,car,van',
                'vehicle_number' => 'nullable|string|max:50',
                'license_number' => 'nullable|string|max:50',
            ]);

            if ($validator->fails()) {
                return redirect()->route('office.register_user')
                    ->withErrors($validator)
                    ->withInput();
            }
        }

        try {
            // Create user
            $newUser = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'phone' => $request->phone,
                'role' => $request->role,
                'status' => 'active',
            ]);

            // Create merchant or rider profile
            if ($request->role === 'merchant') {
                Merchant::create([
                    'user_id' => $newUser->id,
                    'business_name' => $request->business_name,
                    'business_address' => $request->business_address,
                    'business_phone' => $request->business_phone,
                    'business_email' => $request->business_email,
                    'status' => 'pending',
                ]);
            } elseif ($request->role === 'rider') {
                Rider::create([
                    'user_id' => $newUser->id,
                    'name' => $request->name,
                    'phone' => $request->phone ?? $request->input('rider_phone'),
                    'vehicle_type' => $request->vehicle_type,
                    'vehicle_number' => $request->vehicle_number,
                    'license_number' => $request->license_number,
                    'status' => 'offline',
                ]);
            }

            return redirect()->route('office.register_user')
                ->with('success', ucfirst($request->role) . ' account created successfully!');
        } catch (\Exception $e) {
            Log::error('User registration error: ' . $e->getMessage());
            return redirect()->route('office.register_user')
                ->with('error', 'Failed to create user account. Please try again.')
                ->withInput();
        }
    }

    protected function getApiToken()
    {
        $user = auth()->user();
        // Check if token exists in session to avoid database query
        $sessionKey = 'api_token_' . $user->id;
        if (session()->has($sessionKey)) {
            return session($sessionKey);
        }
        
        // Get existing token or create a new one
        $token = $user->tokens()->where('name', 'web-session')->first();
        if (!$token) {
            // Only create if it doesn't exist
            $token = $user->createToken('web-session');
            $plainToken = $token->plainTextToken;
            session([$sessionKey => $plainToken]);
            return $plainToken;
        }
        
        // For existing tokens, we need to return the plain text token
        // Since we can't get plain text from existing tokens, create a new one
        // But limit to one token per user to avoid accumulation
        $user->tokens()->where('name', 'web-session')->delete();
        $token = $user->createToken('web-session');
        $plainToken = $token->plainTextToken;
        session([$sessionKey => $plainToken]);
        return $plainToken;
    }
}

