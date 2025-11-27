@extends('layouts.office')

@section('title', 'Registered Packages by Merchant')
@section('page-title', 'Registered Packages by Merchant Shop')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="bg-white rounded-lg shadow p-6">
        <div class="flex justify-between items-center">
            <div>
                <h2 class="text-2xl font-bold text-gray-800">Registered Packages by Merchant</h2>
                <p class="text-gray-600 mt-1">Assign riders to pick up packages from merchant shops</p>
            </div>
            <a href="{{ route('office.packages') }}" class="bg-gray-200 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-300">
                <i class="fas fa-arrow-left mr-1"></i> Back to All Packages
            </a>
        </div>
    </div>

    <!-- Merchants List -->
    @forelse($merchants as $merchant)
        @php
            $merchantPackages = $packagesByMerchant->get($merchant->id, collect());
            $packageCount = $merchantPackages->count();
        @endphp
        <div class="bg-white rounded-lg shadow overflow-hidden">
            <!-- Merchant Header -->
            <div class="bg-gradient-to-r from-blue-500 to-blue-600 p-6 text-white">
                <div class="flex justify-between items-start">
                    <div class="flex-1">
                        <h3 class="text-xl font-bold mb-2">{{ $merchant->business_name }}</h3>
                        <div class="space-y-1 text-blue-100">
                            <div class="flex items-center">
                                <i class="fas fa-map-marker-alt mr-2"></i>
                                <span>{{ $merchant->business_address }}</span>
                            </div>
                            <div class="flex items-center">
                                <i class="fas fa-phone mr-2"></i>
                                <span>{{ $merchant->business_phone }}</span>
                            </div>
                        </div>
                    </div>
                    <div class="text-right">
                        <div class="bg-white bg-opacity-20 rounded-lg px-4 py-2">
                            <div class="text-sm text-blue-100">Total Packages</div>
                            <div class="text-3xl font-bold">{{ $packageCount }}</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Packages List -->
            <div class="p-6">
                <div class="mb-4 flex justify-between items-center">
                    <h4 class="text-lg font-semibold text-gray-800">Packages ({{ $packageCount }})</h4>
                    <button 
                        onclick="assignPickupToMerchant({{ $merchant->id }})" 
                        class="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 text-sm">
                        <i class="fas fa-user-plus mr-1"></i> Assign Rider for Pickup
                    </button>
                </div>

                @if($packageCount > 0)
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tracking Code</th>
                                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Customer</th>
                                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Address</th>
                                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Assigned Rider</th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                @foreach($merchantPackages as $package)
                                <tr class="hover:bg-gray-50">
                                    <td class="px-4 py-3 whitespace-nowrap">
                                        <span class="font-mono text-blue-600">{{ $package->tracking_code }}</span>
                                    </td>
                                    <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                                        <div>{{ $package->customer_name }}</div>
                                        <div class="text-xs text-gray-500">{{ $package->customer_phone }}</div>
                                    </td>
                                    <td class="px-4 py-3 text-sm text-gray-900 max-w-xs truncate">
                                        {{ $package->delivery_address }}
                                    </td>
                                    <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                                        {{ number_format($package->amount, 2) }} {{ $package->payment_type == 'cod' ? '(COD)' : '' }}
                                    </td>
                                    <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                                        {{ $package->created_at->format('M d, Y') }}
                                    </td>
                                    <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                                        @if($package->currentRider)
                                            <span class="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-xs">
                                                {{ $package->currentRider->name }}
                                            </span>
                                        @else
                                            <span class="text-gray-400">Unassigned</span>
                                        @endif
                                    </td>
                                </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                @else
                    <div class="text-center py-8 text-gray-500">
                        <i class="fas fa-inbox text-4xl mb-2"></i>
                        <p>No registered packages for this merchant</p>
                    </div>
                @endif
            </div>
        </div>
    @empty
        <div class="bg-white rounded-lg shadow p-12 text-center">
            <i class="fas fa-inbox text-6xl text-gray-300 mb-4"></i>
            <h3 class="text-xl font-semibold text-gray-700 mb-2">No Registered Packages</h3>
            <p class="text-gray-500">There are no registered packages to display.</p>
        </div>
    @endforelse
</div>

<!-- Assign Pickup Modal -->
<div id="assignPickupModal" class="hidden fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
    <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-1/2 shadow-lg rounded-md bg-white">
        <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-semibold">Assign Rider for Pickup</h3>
            <button onclick="closeAssignPickupModal()" class="text-gray-400 hover:text-gray-600">
                <i class="fas fa-times"></i>
            </button>
        </div>
        <form id="assignPickupForm" onsubmit="submitAssignPickup(event)">
            <input type="hidden" id="assignPickupMerchantId" name="merchant_id">
            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-2">Select Rider</label>
                <select id="assignPickupRiderId" name="rider_id" class="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" required>
                    <option value="">Choose a rider...</option>
                    @foreach($riders as $rider)
                        <option value="{{ $rider->id }}">{{ $rider->name }} ({{ $rider->status }})</option>
                    @endforeach
                </select>
            </div>
            <div class="flex justify-end space-x-2">
                <button type="button" onclick="closeAssignPickupModal()" class="bg-gray-200 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-300">
                    Cancel
                </button>
                <button type="submit" class="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700">
                    Assign
                </button>
            </div>
        </form>
    </div>
</div>

@push('scripts')
<script>
    function assignPickupToMerchant(merchantId) {
        document.getElementById('assignPickupMerchantId').value = merchantId;
        document.getElementById('assignPickupModal').classList.remove('hidden');
    }

    function closeAssignPickupModal() {
        document.getElementById('assignPickupModal').classList.add('hidden');
        document.getElementById('assignPickupForm').reset();
    }

    function submitAssignPickup(e) {
        e.preventDefault();
        const merchantId = document.getElementById('assignPickupMerchantId').value;
        const riderId = document.getElementById('assignPickupRiderId').value;

        fetch(`/api/office/merchants/${merchantId}/assign-pickup`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer {{ $apiToken }}',
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({ rider_id: riderId })
        })
        .then(async res => {
            // Get response text first to check if it's empty
            const text = await res.text();
            
            // Log the actual response for debugging
            console.log('Response status:', res.status);
            console.log('Response headers:', [...res.headers.entries()]);
            console.log('Response text length:', text.length);
            console.log('Response text (first 500 chars):', text.substring(0, 500));
            
            if (!res.ok) {
                // Try to parse as JSON, fallback to text
                let errorMessage = 'Failed to assign rider';
                try {
                    const error = JSON.parse(text);
                    errorMessage = error.message || error.error || errorMessage;
                } catch (e) {
                    errorMessage = text || `HTTP ${res.status}: ${res.statusText}`;
                }
                throw new Error(errorMessage);
            }
            
            // Check if response is empty or just whitespace
            const trimmedText = text.trim();
            if (!trimmedText) {
                console.error('Response is empty or only whitespace');
                throw new Error('Empty response from server');
            }
            
            // Try to parse JSON
            try {
                const data = JSON.parse(trimmedText);
                console.log('Parsed JSON successfully:', data);
                return data;
            } catch (e) {
                console.error('Failed to parse JSON. Response text:', trimmedText);
                console.error('Parse error:', e);
                // If it looks like HTML, it might be an error page
                if (trimmedText.startsWith('<!DOCTYPE') || trimmedText.startsWith('<html')) {
                    throw new Error('Server returned HTML instead of JSON. Check server logs.');
                }
                throw new Error('Invalid JSON response: ' + e.message);
            }
        })
        .then(data => {
            alert('Rider assigned successfully for pickup from merchant!');
            location.reload();
        })
        .catch(err => {
            alert('Error assigning rider: ' + err.message);
            console.error('Full error:', err);
        });
    }
</script>
@endpush

@endsection

