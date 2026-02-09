<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Populate merchant_id for users who have a merchant profile
        // Using Laravel's query builder for better compatibility
        $merchants = DB::table('merchants')
            ->join('users', 'merchants.user_id', '=', 'users.id')
            ->where('users.role', 'merchant')
            ->select('users.id as user_id', 'merchants.id as merchant_id')
            ->get();

        foreach ($merchants as $merchant) {
            DB::table('users')
                ->where('id', $merchant->user_id)
                ->update(['merchant_id' => $merchant->merchant_id]);
        }

        // Populate rider_id for users who have a rider profile
        $riders = DB::table('riders')
            ->join('users', 'riders.user_id', '=', 'users.id')
            ->where('users.role', 'rider')
            ->select('users.id as user_id', 'riders.id as rider_id')
            ->get();

        foreach ($riders as $rider) {
            DB::table('users')
                ->where('id', $rider->user_id)
                ->update(['rider_id' => $rider->rider_id]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Clear merchant_id and rider_id
        DB::table('users')->update([
            'merchant_id' => null,
            'rider_id' => null,
        ]);
    }
};
