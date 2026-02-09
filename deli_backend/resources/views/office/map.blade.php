@extends('layouts.office')

@section('title', 'Live Map')
@section('page-title',   'Live Rider Map')

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
                <span class="text-sm text-gray-700">Manual refresh (30s)</span>
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
<script src="https://cdn.socket.io/4.6.1/socket.io.min.js"></script>
<script>
    // Debug: Log script execution
    console.log('Map script loaded at:', new Date().toISOString());
    let map;
    let markers = {};
    let autoRefreshInterval = null;
    let isInitialLoad = true; // Track if this is the first load
    const API_BASE = '/api/office';
    const TOKEN = '{{ $apiToken }}';

    function initMap() {
        try {
            // Check if map container exists
            const mapContainer = document.getElementById('map');
            if (!mapContainer) {
                console.error('Map container element not found');
                return;
            }
            
        // Default center - Yangon, Myanmar
        const defaultCenter = [96.1951, 16.8661]; // [lng, lat] for MapLibre - Yangon, Myanmar
            
            // Check if maplibregl is loaded
            if (typeof maplibregl === 'undefined') {
                console.error('MapLibre GL is not loaded');
                const loadingIndicator = document.getElementById('mapLoading');
                if (loadingIndicator) {
                    loadingIndicator.innerHTML = '<div style="text-align: center; padding: 20px;"><p style="color: #ef4444;">Error: Map library failed to load. Please refresh the page.</p></div>';
                }
                return;
            }
            
            console.log('Initializing map...');
        
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
                console.log('Map loaded successfully');
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
            
            // Handle style loading errors
            map.on('style.load', function() {
                console.log('Map style loaded');
            });
            
        } catch (error) {
            console.error('Error initializing map:', error);
            const loadingIndicator = document.getElementById('mapLoading');
            if (loadingIndicator) {
                loadingIndicator.innerHTML = '<div style="text-align: center; padding: 20px;"><p style="color: #ef4444;">Error initializing map: ' + error.message + '</p><button onclick="initMap()" style="margin-top: 10px; padding: 8px 16px; background: #3b82f6; color: white; border: none; border-radius: 4px; cursor: pointer;">Retry</button></div>';
            }
        }
    }

    function loadRiderLocations() {
        // Show loading state
        document.getElementById('riderList').innerHTML = '<p class="text-gray-500 text-center">Loading riders...</p>';
        
        // Debug: Log the API endpoint and token status
        console.log('API_BASE:', API_BASE);
        console.log('Full URL:', `${API_BASE}/riders/locations`);
        console.log('Token exists:', !!TOKEN);
        console.log('Token length:', TOKEN ? TOKEN.length : 0);
        
        // Check if token exists
        if (!TOKEN || TOKEN.trim() === '') {
            console.error('API token is missing');
            document.getElementById('riderList').innerHTML = '<p class="text-red-500 text-center">Error: Authentication token is missing. Please refresh the page.</p>';
            return;
        }
        
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
                
                // Handle 401 Unauthorized
                if (res.status === 401) {
                    throw new Error('Authentication failed. Please refresh the page to login again.');
                }
                
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
            const riders = data.riders || [];
            
            // Cache rider data for Socket.io updates (normalize to number keys)
            riders.forEach(rider => {
                if (rider.rider_id) {
                    const riderIdNum = Number(rider.rider_id);
                    riderDataCache[riderIdNum] = {
                        name: rider.name,
                        phone: rider.phone,
                        status: rider.status,
                        package_count: rider.package_count || 0
                    };
                    // Also cache with string key for compatibility
                    riderDataCache[String(rider.rider_id)] = riderDataCache[riderIdNum];
                }
            });
            
            updateRiderList(riders);
            updateMapMarkers(riders);
            document.getElementById('riderCount').textContent = riders.length;
        })
        .catch(err => {
            console.error('Error loading rider locations:', err);
            const errorMessage = err.message || 'Unknown error';
            document.getElementById('riderList').innerHTML = '<p class="text-red-500 text-center">Error loading riders: ' + errorMessage + '</p>';
            
            // If map is loaded, show error on map too
            if (map) {
                const loadingIndicator = document.getElementById('mapLoading');
                if (loadingIndicator) {
                    loadingIndicator.style.display = 'flex';
                    loadingIndicator.innerHTML = '<div style="text-align: center; padding: 20px;"><p style="color: #ef4444;">Error loading rider locations: ' + errorMessage + '</p><button onclick="loadRiderLocations()" style="margin-top: 10px; padding: 8px 16px; background: #3b82f6; color: white; border: none; border-radius: 4px; cursor: pointer;">Retry</button></div>';
                }
            }
        });
    }

    function updateMapMarkers(riders) {
        // Instead of clearing all markers, update existing ones and remove only those not in the new data
        const newRiderIds = new Set(riders.map(r => Number(r.rider_id))); // Normalize to numbers
        
        // Remove markers for riders that are no longer in the list
        Object.keys(markers).forEach(key => {
            const riderId = Number(key);
            if (!newRiderIds.has(riderId)) {
                markers[key].remove();
                delete markers[key];
            }
        });

        if (riders.length === 0) {
            return;
        }

        // Create bounds to fit all riders
        const bounds = [];

        riders.forEach(rider => {
            if (!rider.latitude || !rider.longitude) return;

            const position = [parseFloat(rider.longitude), parseFloat(rider.latitude)]; // [lng, lat] for MapLibre
            bounds.push(position);
            
            // Normalize rider_id to number for consistent key lookup
            const riderIdNum = Number(rider.rider_id);
            const riderIdStr = String(rider.rider_id);
            
            // Check if marker already exists (from Socket.io update or previous API call)
            const existingMarker = markers[riderIdNum] || markers[riderIdStr] || markers[rider.rider_id];
            
            if (existingMarker) {
                // Update existing marker position and popup instead of creating duplicate
                existingMarker.setLngLat(position);
                
                // Update popup content
                const popupContent = `
                    <div style="padding: 5px;">
                        <h3 style="margin: 0 0 5px 0; font-size: 16px; font-weight: 600;">${rider.name}</h3>
                        <p style="margin: 3px 0; font-size: 14px; color: #666;">${rider.phone}</p>
                        <p style="margin: 3px 0; font-size: 14px;">Status: <span style="font-weight: 500;">${rider.status}</span></p>
                        <p style="margin: 3px 0; font-size: 14px;">Packages: <span style="font-weight: 500;">${rider.package_count || 0}</span></p>
                        <p style="margin: 5px 0 0 0; font-size: 12px; color: #999;">Last update: ${rider.last_location_update ? new Date(rider.last_location_update).toLocaleString() : 'N/A'}</p>
                    </div>
                `;
                const popup = new maplibregl.Popup({ offset: 25 }).setHTML(popupContent);
                existingMarker.setPopup(popup);
                
                // Update marker label
                const markerElement = existingMarker.getElement();
                const nameLabel = markerElement.querySelector('div:last-child');
                if (nameLabel && nameLabel.textContent !== rider.name) {
                    nameLabel.textContent = rider.name;
                }
                
                // Normalize key to number
                if (!markers[riderIdNum]) {
                    markers[riderIdNum] = existingMarker;
                    // Clean up old keys
                    if (markers[riderIdStr] && riderIdStr != String(riderIdNum)) {
                        delete markers[riderIdStr];
                    }
                    if (markers[rider.rider_id] && rider.rider_id != riderIdNum) {
                        delete markers[rider.rider_id];
                    }
                }
                
                return; // Skip creating new marker
            }

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

            // Store marker with normalized number key (riderIdNum already declared above)
            markers[riderIdNum] = marker;
        });

        // Only fit map to show all riders on initial load
        // After that, preserve user's zoom/pan position
        if (isInitialLoad && bounds.length > 0) {
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
            isInitialLoad = false; // Mark that initial load is complete
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
            autoRefreshInterval = setInterval(loadRiderLocations, 30000); // 30 seconds (only for manual refresh)
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
    // Wait for both DOM and MapLibre library to be ready
    let mapLibreWaitAttempts = 0;
    const MAX_WAIT_ATTEMPTS = 50; // 5 seconds max wait
    
    function waitForMapLibreAndInit() {
        if (typeof maplibregl !== 'undefined') {
            console.log('MapLibre GL is loaded, initializing map...');
            initMap();
        } else {
            mapLibreWaitAttempts++;
            if (mapLibreWaitAttempts >= MAX_WAIT_ATTEMPTS) {
                console.error('MapLibre GL failed to load after waiting');
                const loadingIndicator = document.getElementById('mapLoading');
                if (loadingIndicator) {
                    loadingIndicator.innerHTML = '<div style="text-align: center; padding: 20px;"><p style="color: #ef4444;">Error: Map library failed to load. Please check your internet connection and refresh the page.</p><button onclick="location.reload()" style="margin-top: 10px; padding: 8px 16px; background: #3b82f6; color: white; border: none; border-radius: 4px; cursor: pointer;">Refresh Page</button></div>';
                }
                return;
            }
            setTimeout(waitForMapLibreAndInit, 100);
        }
    }
    
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            // Wait a bit for scripts to load
            setTimeout(waitForMapLibreAndInit, 100);
        });
    } else {
        // DOM already loaded, wait for MapLibre
        setTimeout(waitForMapLibreAndInit, 100);
    }
    
    // Don't auto-refresh by default - use Socket.io for real-time updates instead
    // Auto-refresh checkbox is now optional for manual periodic refresh only
    
    // Socket.io: Connect to JavaScript Location Tracker server for real-time rider location updates
    let socket = null;
    const LOCATION_TRACKER_URL = '{{ config("services.location_tracker.url", "http://localhost:3000") }}';
    
    function connectSocket() {
        // Check if Socket.io is loaded
        if (typeof io === 'undefined') {
            console.warn('Socket.io library not loaded. Real-time updates will not work.');
            return;
        }
        
        // Check if LOCATION_TRACKER_URL is valid
        if (!LOCATION_TRACKER_URL || LOCATION_TRACKER_URL === '') {
            console.warn('LOCATION_TRACKER_URL is not configured. Real-time updates will not work.');
            return;
        }
        
        console.log('Connecting to Location Tracker server:', LOCATION_TRACKER_URL);
        
        try {
            socket = io(LOCATION_TRACKER_URL, {
                transports: ['websocket', 'polling'],
                reconnection: true,
                reconnectionDelay: 1000,
                reconnectionDelayMax: 5000,
                reconnectionAttempts: Infinity,
                timeout: 5000
            });
            
            socket.on('connect', () => {
                console.log('Socket.io connected successfully');
                
                // Join office room to receive all rider locations
                socket.emit('join:office');
            });
            
            socket.on('connected', (data) => {
                console.log('Socket.io connection confirmed:', data);
            });
            
            // Receive all current rider locations when joining
            socket.on('location:all', (locations) => {
                console.log('Received all rider locations:', locations);
                // Only update markers, don't reset map view
                if (Array.isArray(locations)) {
                locations.forEach(location => {
                    updateRiderLocationOnMap(location);
                });
                }
            });
            
            // Receive real-time location updates
            socket.on('location:update', (data) => {
                console.log('Location update received:', data);
                updateRiderLocationOnMap(data);
            });
            
            socket.on('disconnect', () => {
                console.log('Socket.io disconnected. Will reconnect automatically...');
            });
            
            socket.on('connect_error', (error) => {
                console.warn('Socket.io connection error:', error.message);
                // Don't spam retries - let the reconnection handle it
            });
            
            socket.on('error', (error) => {
                console.error('Socket.io error:', error);
            });
        } catch (e) {
            console.error('Failed to connect to Socket.io:', e);
            // Retry after 5 seconds
            setTimeout(() => {
                connectSocket();
            }, 5000);
        }
    }
    
    // Connect when page loads
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', connectSocket);
    } else {
        connectSocket();
    }
    
    // Clean up on page unload
    window.addEventListener('beforeunload', () => {
        if (socket) {
            socket.disconnect();
        }
    });
    
    // Store rider data for creating markers
    let riderDataCache = {};
    
    function updateRiderLocationOnMap(data) {
        if (!map || !data.latitude || !data.longitude) return;
        
        // IMPORTANT: Only use rider_id, not user_id
        // The rider app now sends rider_id (from riders table), not user_id (from users table)
        const riderId = data.rider_id || data.riderId;
        if (!riderId) {
            console.warn('updateRiderLocationOnMap: No rider_id in data', data);
            return;
        }
        
        // Normalize riderId to number for consistent key lookup (declare once)
        const riderIdNum = Number(riderId);
        const riderIdStr = String(riderId);
        
        // Safety check: If rider_id looks like a user_id (e.g., 10) but we have cached data for a different rider_id (e.g., 2),
        // it means we're receiving wrong data - skip it
        const cachedData = riderDataCache[riderIdNum] || riderDataCache[riderIdStr];
        if (!cachedData) {
            // No cached data means this rider_id hasn't been loaded from API yet
            // This could be old data with wrong rider_id - skip it to prevent duplicates
            console.warn('updateRiderLocationOnMap: No cached data for rider_id:', riderIdNum, '- skipping to prevent duplicate markers');
            return;
        }
        
        const position = [parseFloat(data.longitude), parseFloat(data.latitude)];
        
        console.log('Updating rider location:', riderId, position);
        
        // Update existing marker position smoothly (without resetting map view)
        
        // Check both string and number keys (API might return string, Socket.io might return number)
        const existingMarker = markers[riderIdNum] || markers[riderIdStr] || markers[riderId];
        
        if (existingMarker) {
            // Normalize the key to ensure consistency (use number as standard)
            if (!markers[riderIdNum]) {
                markers[riderIdNum] = existingMarker;
                // Clean up old keys if different
                if (markers[riderIdStr] && riderIdStr != String(riderIdNum)) {
                    delete markers[riderIdStr];
                }
                if (markers[riderId] && riderId != riderIdNum) {
                    delete markers[riderId];
                }
            }
            
            // Smoothly update marker position without affecting map zoom/pan
            existingMarker.setLngLat(position);
            
            // Update marker label if we have cached rider data
            const riderName = cachedData.name || `Rider ${riderIdNum}`;
            const markerElement = existingMarker.getElement();
            const nameLabel = markerElement.querySelector('div:last-child');
            if (nameLabel && nameLabel.textContent !== riderName) {
                nameLabel.textContent = riderName;
            }
            
            // Update popup with latest timestamp if available
            if (data.timestamp || data.last_update) {
                const timestamp = data.timestamp || data.last_update;
                const popupContent = `
                    <div style="padding: 5px;">
                        <h3 style="margin: 0 0 5px 0; font-size: 16px; font-weight: 600;">${riderName}</h3>
                        <p style="margin: 3px 0; font-size: 14px; color: #666;">${cachedData.phone || 'N/A'}</p>
                        <p style="margin: 3px 0; font-size: 14px;">Status: <span style="font-weight: 500;">${cachedData.status || 'active'}</span></p>
                        <p style="margin: 3px 0; font-size: 14px;">Packages: <span style="font-weight: 500;">${cachedData.package_count || 0}</span></p>
                        <p style="margin: 5px 0 0 0; font-size: 12px; color: #999;">Last update: ${new Date(timestamp).toLocaleString()}</p>
                    </div>
                `;
                const popup = new maplibregl.Popup({ offset: 25 })
                    .setHTML(popupContent);
                existingMarker.setPopup(popup);
            }
        } else {
            // Marker doesn't exist yet - but check if we should update existing instead of creating duplicate
            // This handles cases where rider_id format differs (string vs number)
            console.log('Marker not found for rider_id:', riderId, 'Available markers:', Object.keys(markers));
            
            // Check if there's a marker with the same rider but different key format
            // Try to find by matching cached rider names
            // Note: cachedData already declared above, reuse it
            let foundExisting = false;
            if (cachedData && cachedData.name) {
                // Search for existing marker by checking all markers and their cached data
                for (const [key, marker] of Object.entries(markers)) {
                    const keyData = riderDataCache[Number(key)] || riderDataCache[String(key)] || riderDataCache[key];
                    if (keyData && keyData.name === cachedData.name) {
                        console.log('Found existing marker with different key:', key, 'updating instead of creating new');
                        // Normalize to number key
                        markers[riderIdNum] = marker;
                        if (key != riderIdNum) {
                            delete markers[key];
                        }
                        marker.setLngLat(position);
                        foundExisting = true;
                        break;
                    }
                }
            }
            
            if (foundExisting) {
                return; // Already updated, don't create duplicate
            }
            
            // Marker doesn't exist yet - create it without reloading the entire map
            // IMPORTANT: Only create marker if we have cached rider data (from API)
            // This prevents creating markers with wrong rider_id (e.g., user_id instead of rider_id)
            if (!cachedData || !cachedData.name) {
                console.warn('Cannot create marker for rider_id:', riderIdNum, '- no cached rider data. Waiting for API load...');
                return; // Don't create marker without proper rider data
            }
            
            // Use cached rider data
            const riderName = cachedData.name;
            const riderPhone = cachedData.phone || 'N/A';
            const riderStatus = cachedData.status || 'active';
            const packageCount = cachedData.package_count || 0;
            
            // Create marker element
            const el = document.createElement('div');
            el.style.display = 'flex';
            el.style.flexDirection = 'column';
            el.style.alignItems = 'center';
            el.style.cursor = 'pointer';
            
            const markerDot = document.createElement('div');
            markerDot.className = 'rider-marker';
            markerDot.style.width = '20px';
            markerDot.style.height = '20px';
            markerDot.style.borderRadius = '50%';
            markerDot.style.backgroundColor = '#ef4444';
            markerDot.style.border = '3px solid white';
            markerDot.style.boxShadow = '0 2px 4px rgba(0,0,0,0.3)';
            
            const nameLabel = document.createElement('div');
            nameLabel.textContent = riderName;
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
            
            // Create popup
            const timestamp = data.timestamp || data.last_update || new Date().toISOString();
            const popupContent = `
                <div style="padding: 5px;">
                    <h3 style="margin: 0 0 5px 0; font-size: 16px; font-weight: 600;">${riderName}</h3>
                    <p style="margin: 3px 0; font-size: 14px; color: #666;">${riderPhone}</p>
                    <p style="margin: 3px 0; font-size: 14px;">Status: <span style="font-weight: 500;">${riderStatus}</span></p>
                    <p style="margin: 3px 0; font-size: 14px;">Packages: <span style="font-weight: 500;">${packageCount}</span></p>
                    <p style="margin: 5px 0 0 0; font-size: 12px; color: #999;">Last update: ${new Date(timestamp).toLocaleString()}</p>
                </div>
            `;
            
            const popup = new maplibregl.Popup({ offset: 25 })
                .setHTML(popupContent);
            
            marker.setPopup(popup);
            // Store marker with normalized number key
            markers[riderIdNum] = marker;
            // Also cache rider data with number key if not already cached
            if (!riderDataCache[riderIdNum]) {
                riderDataCache[riderIdNum] = {
                    name: riderName,
                    phone: riderPhone,
                    status: riderStatus,
                    package_count: packageCount
                };
            }
        }
    }
</script>
@endpush
@endsection