# Rider App - Workflow & API Analysis

## 📱 App Structure

### Main Navigation
- **3 Tabs**: Deliver, Pickup, Settings
- **State Management**: BLoC Pattern (flutter_bloc)
- **Architecture**: Repository Pattern with Services

### Screens
1. **Login Screen** - Authentication
2. **Main Screen** - Bottom navigation container
3. **Deliver Screen** - Delivery assignments list
4. **Pickup Screen** - Pickup assignments grouped by merchant
5. **Settings Screen** - User settings
6. **Date Packages Screen** - Packages grouped by date
7. **Assignments Screen** - All assignments list

---

## 🔄 Workflow

### 1. Authentication Flow
- Rider logs in with email/password
- System validates rider role
- Token stored in SharedPreferences
- Auto-start location tracking on login

### 2. Pickup Workflow
1. **View Pickup Assignments**
   - Packages with status `assigned_to_rider` (from merchant)
   - Grouped by merchant
   - Shows merchant info (name, address, phone)
   - Lists all packages to pick up from that merchant

2. **Confirm Pickup**
   - Rider arrives at merchant location
   - Clicks "Confirm Pickup" button
   - Captures current GPS location
   - Updates all packages from that merchant to `picked_up` status
   - Packages move to delivery workflow

### 3. Delivery Workflow
1. **Receive from Office** (if assigned for delivery)
   - Package status: `assigned_to_rider` (previous status was `arrived_at_office`)
   - Rider clicks "Receive from Office"
   - Status changes to `ready_for_delivery`

2. **Start Delivery**
   - Package status: `ready_for_delivery` or `picked_up`
   - Rider clicks "Start Delivery"
   - Status changes to `on_the_way`
   - Rider status changes to `busy`
   - Location tracking starts for this package

3. **During Delivery** (`on_the_way`)
   - **Collect COD** (if payment type is COD)
     - Enter amount
     - Take photo proof (optional)
     - Status automatically changes to `delivered`
   - **Can't Contact Customer**
     - Enter reason for contact failure
     - Status changes to `contact_failed`
     - Package automatically reassigned (status becomes `arrived_at_office`)
     - Removed from rider's list

4. **Return to Office** (for cancelled packages)
   - Package status: `cancelled`
   - Rider clicks "Return to Office"
   - Status changes to `return_to_office`
   - Package removed from rider's assignments

5. **Cancel Package**
   - Available for: `assigned_to_rider`, `ready_for_delivery`, `on_the_way`
   - Rider can cancel with optional reason
   - Status changes to `cancelled`

### 4. Location Tracking
- **Automatic**: Starts when rider logs in
- **Package-specific**: When delivery starts (`on_the_way`)
- **Updates**: Sent to backend every few seconds
- **Broadcast**: Via WebSocket to office for real-time tracking

---

## 🔌 API Endpoints Used

### Authentication APIs
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/login` | Rider login |
| `POST` | `/api/auth/logout` | Rider logout |
| `GET` | `/api/auth/user` | Get current user info |

### Package Management APIs
| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| `GET` | `/api/rider/packages` | Get all assigned packages | - |
| `GET` | `/api/rider/packages/{id}` | Get package details | - |
| `PUT` | `/api/rider/packages/{id}/status` | Update package status | `{status, notes?, latitude?, longitude?}` |
| `POST` | `/api/rider/packages/{id}/receive-from-office` | Receive package from office | `{notes?}` |
| `POST` | `/api/rider/packages/{id}/start-delivery` | Start delivery | - |
| `POST` | `/api/rider/packages/{id}/contact-customer` | Record contact result | `{contact_result: 'success'\|'failed', notes?}` |
| `POST` | `/api/rider/packages/{id}/proof` | Upload delivery proof | `{proof_type, proof_data, delivery_latitude?, delivery_longitude?, delivered_to_name?, delivered_to_phone?, notes?}` |
| `POST` | `/api/rider/packages/{id}/cod` | Collect COD payment | `{amount, collection_proof?}` (multipart) |
| `POST` | `/api/rider/merchants/{merchantId}/confirm-pickup` | Confirm pickup from merchant | `{notes?, latitude?, longitude?}` |

### Location APIs
| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| `POST` | `/api/rider/location` | Update rider location | `{latitude, longitude, speed?, heading?, package_id?}` |
| `GET` | `/api/rider/location` | Get current location | - |

### Notification APIs (Optional - Firebase)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/notifications/register-token` | Register FCM token |
| `POST` | `/api/notifications/unregister-token` | Unregister FCM token |

---

## 📊 Package Status Flow

```
registered → arrived_at_office → assigned_to_rider → ready_for_delivery → on_the_way → delivered
                                                      ↓
                                              (pickup from merchant)
                                                      ↓
                                              picked_up → on_the_way → delivered
                                                              ↓
                                                      contact_failed → arrived_at_office (reassigned)
                                                              ↓
                                                      cancelled → return_to_office
```

### Status Descriptions
- **`registered`**: Package registered by merchant
- **`arrived_at_office`**: Package arrived at office
- **`assigned_to_rider`**: Assigned to rider (can be pickup or delivery)
- **`picked_up`**: Picked up from merchant (legacy status)
- **`ready_for_delivery`**: Received from office, ready to deliver
- **`on_the_way`**: Currently being delivered
- **`delivered`**: Successfully delivered
- **`contact_failed`**: Could not contact customer (auto-reassigned)
- **`cancelled`**: Package cancelled
- **`return_to_office`**: Returned to office

---

## 🎯 Key Features

### 1. Assignment Filtering
- **Deliver Tab**: Shows packages for delivery
  - `assigned_to_rider` (with previous status `arrived_at_office`)
  - `ready_for_delivery`
  - `on_the_way`
  - `cancelled`
  
- **Pickup Tab**: Shows packages for pickup
  - `assigned_to_rider` (from merchant, previous status was `registered`)
  - Grouped by merchant

### 2. Location Tracking
- Automatic background location updates
- Package-specific tracking when `on_the_way`
- Real-time location broadcast to office

### 3. COD Collection
- Amount input
- Photo proof (optional)
- Automatic delivery status update

### 4. Contact Management
- Success/Failed contact recording
- Automatic reassignment on contact failure

### 5. Package Grouping
- **Deliver**: Grouped by assigned date
- **Pickup**: Grouped by merchant

---

## 🏗️ Technical Stack

### State Management
- **BLoC Pattern** with freezed
- **BLoCs**:
  - `AuthBloc` - Authentication
  - `AssignmentsBloc` - Package assignments
  - `DeliveryBloc` - Delivery actions
  - `LocationBloc` - Location tracking

### Services
- `AuthService` - Authentication API calls
- `RiderPackageService` - Package operations
- `LocationService` - Location tracking
- `NotificationService` - Push notifications (Firebase)

### Repositories
- `AuthRepository` - Auth operations with token management
- `RiderPackageRepository` - Package operations wrapper

### Dependencies
- `flutter_bloc` - State management
- `dio` - HTTP client
- `geolocator` - Location services
- `image_picker` - Camera/Gallery access
- `firebase_messaging` - Push notifications (optional)
- `shared_preferences` - Local storage
- `url_launcher` - Phone calls, maps

---

## 📝 Notes for New Implementation

1. **Status Logic**: The app distinguishes between pickup and delivery assignments by checking status history
2. **Location Tracking**: Starts automatically on login, not just during delivery
3. **Grouping**: Deliver screen groups by date, Pickup screen groups by merchant
4. **COD**: Only available for packages with `payment_type = 'cod'`
5. **Contact Failed**: Automatically reassigns package (no manual action needed)
6. **Cancelled Packages**: Must be returned to office manually
7. **Real-time Updates**: Uses WebSocket broadcasting (Pusher) for status changes

---

## 🔐 Authentication
- Token-based (Sanctum)
- Role validation: Only `rider` role can access
- Token stored in SharedPreferences
- Auto-logout on token expiration

---

## 📱 UI/UX Current State
- Basic Material Design
- Teal color scheme
- Simple card-based layouts
- Expansion tiles for package details
- Date/merchant grouping
- Search and filter functionality

---

## 🎨 Recommended Improvements for New App
1. **Better Visual Design**: Modern UI with better spacing, colors, typography
2. **Map Integration**: Show delivery locations on map
3. **Navigation**: Turn-by-turn directions to delivery addresses
4. **Offline Support**: Cache assignments for offline viewing
5. **Better Status Indicators**: Visual status badges, progress indicators
6. **Photo Preview**: Better image viewing experience
7. **Myanmar Language Support**: Full localization
8. **Dark Mode**: Theme support
9. **Better Error Handling**: User-friendly error messages
10. **Performance**: Optimize list rendering, image loading

