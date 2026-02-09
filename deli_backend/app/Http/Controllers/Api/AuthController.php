<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Merchant;
use App\Models\Rider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'phone' => 'nullable|string|max:20',
            'role' => 'required|in:merchant,rider',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone' => $request->phone,
            'role' => $request->role,
            'status' => 'active',
        ]);

        // Create merchant or rider profile
        if ($request->role === 'merchant') {
            $request->validate([
                'business_name' => 'required|string|max:255',
                'business_address' => 'required|string',
                'business_phone' => 'required|string',
                'business_email' => 'required|email',
            ]);

            $merchant = Merchant::create([
                'user_id' => $user->id,
                'business_name' => $request->business_name,
                'business_address' => $request->business_address,
                'business_phone' => $request->business_phone,
                'business_email' => $request->business_email,
                'status' => 'pending',
            ]);

            // Update user with merchant_id
            $user->merchant_id = $merchant->id;
            $user->save();
        } elseif ($request->role === 'rider') {
            $request->validate([
                'vehicle_type' => 'required|in:bike,motorcycle,car,van',
                'phone' => 'required|string',
            ]);

            $rider = Rider::create([
                'user_id' => $user->id,
                'name' => $request->name,
                'phone' => $request->phone,
                'vehicle_type' => $request->vehicle_type,
                'vehicle_number' => $request->vehicle_number,
                'license_number' => $request->license_number,
                'status' => 'offline',
            ]);

            // Update user with rider_id
            $user->rider_id = $rider->id;
            $user->save();
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        $user->load($request->role);
        
        return response()->json([
            'message' => 'Registration successful',
            'user' => $user,
            'token' => $token,
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        // Only check user status for riders (merchants are managed via merchant.status)
        if ($user->role === 'rider' && $user->status !== 'active') {
            return response()->json([
                'message' => 'Account is not active',
            ], 403);
        }

        // Set rider status to 'available' when they log in
        if ($user->role === 'rider' && $user->rider) {
            $user->rider->status = 'available';
            $user->rider->save();
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        $user->load($user->role);
        
        return response()->json([
            'message' => 'Login successful',
            'user' => $user,
            'token' => $token,
        ]);
    }

    public function logout(Request $request)
    {
        try {
            $user = $request->user();
            
            if ($user) {
                // Set rider status to 'offline' when they log out
                if ($user->role === 'rider' && $user->rider) {
                    $user->rider->status = 'offline';
                    $user->rider->save();
                }
                
                // Delete the current access token
                $token = $user->currentAccessToken();
                if ($token) {
                    $token->delete();
                }
            }
        } catch (\Exception $e) {
            // Log error but still return success to prevent client from hanging
            \Illuminate\Support\Facades\Log::warning('Logout error', [
                'error' => $e->getMessage(),
                'user_id' => $request->user()?->id ?? null,
            ]);
        }

        return response()->json([
            'message' => 'Logged out successfully',
        ])->header('Content-Type', 'application/json');
    }

    public function user(Request $request)
    {
        $user = $request->user();
        $user->load($user->role);
        
        return response()->json([
            'user' => $user,
        ]);
    }
}
