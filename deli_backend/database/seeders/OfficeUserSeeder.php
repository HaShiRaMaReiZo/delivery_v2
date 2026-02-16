<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class OfficeUserSeeder extends Seeder
{
    /**
     * Seed office users. In production set SEEDER_* env vars; locally uses dev defaults.
     */
    public function run(): void
    {
        $superAdminPassword = env('SEEDER_SUPER_ADMIN_PASSWORD', 'change-me');
        $managerPassword = env('SEEDER_OFFICE_MANAGER_PASSWORD', 'change-me');
        $staffPassword = env('SEEDER_OFFICE_STAFF_PASSWORD', 'change-me');

        User::firstOrCreate(
            ['email' => env('SEEDER_SUPER_ADMIN_EMAIL', 'admin@example.com')],
            [
                'name' => 'Super Admin',
                'email' => env('SEEDER_SUPER_ADMIN_EMAIL', 'admin@example.com'),
                'password' => Hash::make($superAdminPassword),
                'role' => 'super_admin',
                'status' => 'active',
                'phone' => env('SEEDER_SUPER_ADMIN_PHONE', '+1234567890'),
            ]
        );

        User::firstOrCreate(
            ['email' => env('SEEDER_MANAGER_EMAIL', 'manager@example.com')],
            [
                'name' => 'Office Manager',
                'email' => env('SEEDER_MANAGER_EMAIL', 'manager@example.com'),
                'password' => Hash::make($managerPassword),
                'role' => 'office_manager',
                'status' => 'active',
                'phone' => env('SEEDER_MANAGER_PHONE', '+1234567891'),
            ]
        );

        User::firstOrCreate(
            ['email' => env('SEEDER_STAFF_EMAIL', 'staff@example.com')],
            [
                'name' => 'Office Staff',
                'email' => env('SEEDER_STAFF_EMAIL', 'staff@example.com'),
                'password' => Hash::make($staffPassword),
                'role' => 'office_staff',
                'status' => 'active',
                'phone' => env('SEEDER_STAFF_PHONE', '+1234567892'),
            ]
        );

        $this->command->info('Office users created. Set SEEDER_* env vars in production.');
    }
}

