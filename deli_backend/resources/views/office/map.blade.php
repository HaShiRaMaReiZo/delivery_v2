@extends('layouts.office')

@section('title', 'Live Map')
@section('page-title', 'Live Rider Map')

@section('content')
<div class="space-y-6">
    <!-- Map Controls -->
    <div class="bg-white rounded-lg shadow p-4 flex justify-between items-center">
        <div class="flex items-center space-x-4">
            <button onclick="refreshMap()" class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
                <i class="fas fa-sync-alt mr-1"></i> Refresh
            </button>
            <label class="flex items-center space-x-2">
                <input type="checkbox" id="autoRefresh" onchange="toggleAutoRefresh()">
                <span class="text-sm text-gray-700">Auto-refresh (30s)</span>
            </label>
        </div>
        <div class="text-sm text-gray-600">
            <span id="riderCount">0</span> active riders
        </div>
    </div>

    <!-- Map Container -->
    <div class="bg-white rounded-lg shadow">
        <div id="map" style="width: 100%; height: 600px; background: #e5e7eb; position: relative;">
            <div id="mapLoading" style="display: flex; align-items: center; justify-content: center; height: 100%; background: #f3f4f6; position: absolute; top: 0; left: 0; right: 0; bottom: 0; z-index: 1000;">
                <div style="text-align: center;">
                    <div style="border: 4px solid #e5e7eb; border-top: 4px solid #3b82f6; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 10px;"></div>
                    <p style="color: #6b7280; font-size: 14px;">Loading map...</p>
                </div>
            </div>
        </div>
    </div>

    <!-- Rider List -->
    <div class="bg-white rounded-lg shadow">
        <div class="p-4 border-b">
            <h3 class="text-lg font-semibold">Active Riders</h3>
        </div>
        <div id="riderList" class="p-4">
            <p class="text-gray-500 text-center">Loading riders...</p>
        </div>
    </div>
</div>

@push('styles')
<link href='https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.css' rel='stylesheet' />
<style>
    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }
    #map {
        width: 100%;
        height: 600px;
        position: relative;
    }
    .rider-marker {
        background: #3b82f6;
        border-radius: 50%;
        width: 20px;
        height: 20px;
        border: 3px solid white;
        box-shadow: 0 2px 4px rgba(0,0,0,0.3);
        cursor: pointer;
    }
    .rider-marker.busy {
        background: #f59e0b;
    }
    .rider-marker.available {
        background: #10b981;
    }
    .maplibregl-popup-content {
        padding: 10px;
        font-family: system-ui, -apple-system, sans-serif;
    }
    .maplibregl-popup-content h3 {
        margin: 0 0 5px 0;
        font-size: 16px;
        font-weight: 600;
    }
    .maplibregl-popup-content p {
        margin: 3px 0;
        font-size: 14px;
    }
</style>
@endpush

@push('scripts')
<script src='https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.js'></script>
<script>
    let map;
    let markers = {};
    let autoRefreshInterval = null;
    const API_BASE = '/api/office';
    const TOKEN = '{{ $apiToken }}';

    function initMap() {
        // Default center - Yangon, Myanmar
        const defaultCenter = [96.1951, 16.8661]; // [lng, lat] for MapLibre - Yangon, Myanmar
        
        map = new maplibregl.Map({
            container: 'map',
            // Using MapTiler Streets v2 style
            style: 'https://api.maptiler.com/maps/streets-v2/style.json?key=2FU1Toy7etAR00Vzt5Ho',
            center: defaultCenter,
            zoom: 12,
            minZoom: 0,
            maxZoom: 22, // MapTiler supports up to zoom 22
            // Performance optimizations
            antialias: false,
            preserveDrawingBuffer: false,
            fadeDuration: 0
        });

        // Add navigation controls
        map.addControl(new maplibregl.NavigationControl(), 'top-right');

        // Prevent zooming beyond limits to avoid white screen
        const minZoom = 0;
        const maxZoom = 22; // MapTiler supports up to zoom 22
        
        // Clamp zoom level when zoom ends to prevent white screen
        map.on('zoomend', function() {
            const currentZoom = map.getZoom();
            
            // Clamp zoom level if it exceeds limits
            if (currentZoom < minZoom) {
                map.setZoom(minZoom);
            } else if (currentZoom > maxZoom) {
                map.setZoom(maxZoom);
            }
        });
        
        // Also clamp during zoom to prevent going beyond limits
        map.on('zoom', function() {
            const currentZoom = map.getZoom();
            
            // Clamp zoom level if it exceeds limits
            if (currentZoom < minZoom) {
                map.setZoom(minZoom);
            } else if (currentZoom > maxZoom) {
                map.setZoom(maxZoom);
            }
        });

        // Wait for map to load before adding markers
        map.on('load', function() {
            // Hide loading indicator
            const loadingIndicator = document.getElementById('mapLoading');
            if (loadingIndicator) {
                loadingIndicator.style.display = 'none';
            }
            // Load rider locations after map is ready
            setTimeout(() => {
                loadRiderLocations();
            }, 100); // Small delay to ensure map is fully rendered
        });
        
        // Handle map errors
        map.on('error', function(e) {
            console.error('Map error:', e);
            const loadingIndicator = document.getElementById('mapLoading');
            if (loadingIndicator) {
                loadingIndicator.innerHTML = '<div style="text-align: center; padding: 20px;"><p style="color: #ef4444;">Error loading map. Please refresh the page.</p></div>';
            }
        });
    }

    function loadRiderLocations() {
        // Show loading state
        document.getElementById('riderList').innerHTML = '<p class="text-gray-500 text-center">Loading riders...</p>';
        
        // Debug: Log the API endpoint and token status
        console.log('API_BASE:', API_BASE);
        console.log('Full URL:', `${API_BASE}/riders/locations`);
        console.log('Token exists:', !!TOKEN);
        console.log('Token length:', TOKEN ? TOKEN.length : 0);
        
        fetch(`${API_BASE}/riders/locations`, {
            headers: {
                'Authorization': `Bearer ${TOKEN}`,
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            }
        })
        .then(async res => {
            console.log('Response status:', res.status);
            if (!res.ok) {
                // Log response text for debugging
                const text = await res.text();
                console.error('Error response:', text);
                throw new Error(`HTTP error! status: ${res.status}, message: ${text || 'Unknown error'}`);
            }
            
            // Check if response has content
            const text = await res.text();
            if (!text || text.trim() === '') {
                console.warn('Empty response received, using default data');
                return { riders: [] };
            }
            
            // Try to parse JSON
            try {
                return JSON.parse(text);
            } catch (parseError) {
                console.error('JSON parse error:', parseError, 'Response text:', text.substring(0, 200));
                throw new Error('Invalid JSON response from server');
            }
        })
        .then(data => {
            console.log('Rider locations data:', data);
            updateRiderList(data.riders || []);
            updateMapMarkers(data.riders || []);
            document.getElementById('riderCount').textContent = (data.riders || []).length;
        })
        .catch(err => {
            console.error('Error loading rider locations:', err);
            document.getElementById('riderList').innerHTML = '<p class="text-red-500 text-center">Error loading riders: ' + (err.message || 'Unknown error') + '</p>';
        });
    }

    function updateMapMarkers(riders) {
        // Clear existing markers
        Object.values(markers).forEach(marker => marker.remove());
        markers = {};

        if (riders.length === 0) {
            return;
        }

        // Create bounds to fit all riders
        const bounds = [];

        riders.forEach(rider => {
            if (!rider.latitude || !rider.longitude) return;

            const position = [parseFloat(rider.longitude), parseFloat(rider.latitude)]; // [lng, lat] for MapLibre
            bounds.push(position);

            // Create a custom HTML element for the marker with rider name
            const el = document.createElement('div');
            el.style.display = 'flex';
            el.style.flexDirection = 'column';
            el.style.alignItems = 'center';
            el.style.cursor = 'pointer';
            
            // Red pointer/marker
            const markerDot = document.createElement('div');
            markerDot.className = 'rider-marker';
            markerDot.style.width = '20px';
            markerDot.style.height = '20px';
            markerDot.style.borderRadius = '50%';
            markerDot.style.backgroundColor = '#ef4444'; // Red color
            markerDot.style.border = '3px solid white';
            markerDot.style.boxShadow = '0 2px 4px rgba(0,0,0,0.3)';
            
            // Rider name label
            const nameLabel = document.createElement('div');
            nameLabel.textContent = rider.name;
            nameLabel.style.marginTop = '4px';
            nameLabel.style.padding = '2px 6px';
            nameLabel.style.backgroundColor = 'rgba(0, 0, 0, 0.7)';
            nameLabel.style.color = 'white';
            nameLabel.style.fontSize = '11px';
            nameLabel.style.fontWeight = '600';
            nameLabel.style.borderRadius = '4px';
            nameLabel.style.whiteSpace = 'nowrap';
            nameLabel.style.textAlign = 'center';
            nameLabel.style.boxShadow = '0 1px 3px rgba(0,0,0,0.3)';
            
            el.appendChild(markerDot);
            el.appendChild(nameLabel);

            // Create marker
            const marker = new maplibregl.Marker({
                element: el,
                anchor: 'bottom'
            })
            .setLngLat(position)
            .addTo(map);

            // Create popup content
            const popupContent = `
                <div style="padding: 5px;">
                    <h3 style="margin: 0 0 5px 0; font-size: 16px; font-weight: 600;">${rider.name}</h3>
                    <p style="margin: 3px 0; font-size: 14px; color: #666;">${rider.phone}</p>
                    <p style="margin: 3px 0; font-size: 14px;">Status: <span style="font-weight: 500;">${rider.status}</span></p>
                    <p style="margin: 3px 0; font-size: 14px;">Packages: <span style="font-weight: 500;">${rider.package_count || 0}</span></p>
                    <p style="margin: 5px 0 0 0; font-size: 12px; color: #999;">Last update: ${rider.last_location_update ? new Date(rider.last_location_update).toLocaleString() : 'N/A'}</p>
                </div>
            `;

            const popup = new maplibregl.Popup({ offset: 25 })
                .setHTML(popupContent);

            marker.setPopup(popup);

            markers[rider.rider_id] = marker;
        });

        // Fit map to show all riders
        if (bounds.length > 0) {
            if (bounds.length === 1) {
                // Single rider - just center on it
                map.setCenter(bounds[0]);
                const zoom = Math.min(15, 22); // Clamp to max zoom
                map.setZoom(zoom);
            } else {
                // Multiple riders - fit bounds
                const bbox = bounds.reduce((acc, coord) => {
                    return [
                        [Math.min(acc[0][0], coord[0]), Math.min(acc[0][1], coord[1])],
                        [Math.max(acc[1][0], coord[0]), Math.max(acc[1][1], coord[1])]
                    ];
                }, [[bounds[0][0], bounds[0][1]], [bounds[0][0], bounds[0][1]]]);

                map.fitBounds(bbox, {
                    padding: 50,
                    maxZoom: 22 // Clamp to max zoom
                });
            }
        }
    }

    function updateRiderList(riders) {
        if (riders.length === 0) {
            document.getElementById('riderList').innerHTML = '<p class="text-gray-500 text-center">No active riders</p>';
            return;
        }

        const listHtml = riders.map(rider => `
            <div class="border-b last:border-0 py-3 hover:bg-gray-50 cursor-pointer" onclick="focusRider(${rider.rider_id})">
                <div class="flex justify-between items-center">
                    <div>
                        <h4 class="font-semibold text-gray-800">${rider.name}</h4>
                        <p class="text-sm text-gray-600">${rider.phone}</p>
                    </div>
                    <div class="text-right">
                        <span class="px-2 py-1 text-xs font-semibold rounded-full
                            ${rider.status === 'available' ? 'bg-green-100 text-green-800' : 
                              rider.status === 'busy' ? 'bg-yellow-100 text-yellow-800' : 
                              'bg-gray-100 text-gray-800'}">
                            ${rider.status}
                        </span>
                        <p class="text-xs text-gray-500 mt-1">${rider.package_count || 0} packages</p>
                    </div>
                </div>
            </div>
        `).join('');

        document.getElementById('riderList').innerHTML = listHtml;
    }

    function focusRider(riderId) {
        const marker = markers[riderId];
        if (marker) {
            const lngLat = marker.getLngLat();
            const zoom = Math.min(16, 22); // Clamp to max zoom
            map.flyTo({
                center: [lngLat.lng, lngLat.lat],
                zoom: zoom
            });
            marker.togglePopup();
        }
    }

    function refreshMap() {
        loadRiderLocations();
    }

    function toggleAutoRefresh() {
        const checkbox = document.getElementById('autoRefresh');
        if (checkbox.checked) {
            autoRefreshInterval = setInterval(loadRiderLocations, 30000); // 30 seconds
        } else {
            if (autoRefreshInterval) {
                clearInterval(autoRefreshInterval);
                autoRefreshInterval = null;
            }
        }
    }

    // Clean up on page unload
    window.addEventListener('beforeunload', () => {
        if (autoRefreshInterval) {
            clearInterval(autoRefreshInterval);
        }
    });

    // Initialize map when page loads
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initMap);
    } else {
        initMap();
    }
    
    // WebSocket: Listen for real-time rider location updates
    if (window.WebSocketHelper && window.WebSocketHelper.isConnected()) {
        // Use 'private-' prefix for private channels in Pusher
        const riderLocationChannel = window.WebSocketHelper.connect('private-office.riders.locations', 'rider.location.updated', function(data) {
            // Update rider location on map in real-time
            updateRiderLocationOnMap(data);
        });
        
        // Clean up on page unload
        window.addEventListener('beforeunload', () => {
            if (riderLocationChannel) {
                window.WebSocketHelper.disconnect(riderLocationChannel);
            }
        });
    }
    
    function updateRiderLocationOnMap(data) {
        if (!map || !data.latitude || !data.longitude) return;
        
        const riderId = data.rider_id;
        const position = [parseFloat(data.longitude), parseFloat(data.latitude)];
        
        // Update existing marker position smoothly
        if (markers[riderId]) {
            // Smoothly animate marker to new position
            markers[riderId].setLngLat(position);
        } else {
            // Marker doesn't exist yet - reload all locations to get full rider data
            // This will create the marker with proper name and details
            loadRiderLocations();
        }
    }
</script>
@endpush
@endsection

