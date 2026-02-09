# WebSocket Setup for Flutter App

## ✅ Configuration Complete!

1. ✅ Go WebSocket server deployed: `https://location-tracker-4omi.onrender.com`
2. ✅ Flutter app configured with WebSocket URL
3. ✅ `LocationWebSocketService` created
4. ✅ `LiveTrackingMapScreen` updated to use WebSocket

## 🔧 Laravel Configuration

Make sure your Laravel `.env` on Render has:

```env
GO_WEBSOCKET_URL=https://location-tracker-4omi.onrender.com
```

## 📱 How It Works

1. **When package status = `on_the_way`**:
   - WebSocket connects automatically to `wss://location-tracker-4omi.onrender.com/ws`
   - Real-time location updates received instantly
   - Map updates smoothly as rider moves

2. **When package status ≠ `on_the_way`**:
   - WebSocket doesn't connect
   - Uses HTTP API to get last known location (if delivered)

3. **Auto-reconnect**:
   - If connection drops, automatically reconnects after 5 seconds

## 🧪 Testing

1. **Install dependencies** (if not done):
   ```bash
   cd ok_delivery
   flutter pub get
   ```

2. **Run Flutter app**:
   ```bash
   flutter run
   ```

3. **Test WebSocket connection**:
   - Navigate to **Track** page
   - Click on a package with status `on_the_way`
   - You should see live location updates in real-time

4. **Test Go server directly**:
   ```bash
   # Health check
   curl https://location-tracker-4omi.onrender.com/health
   
   # Test WebSocket (using wscat)
   wscat -c "wss://location-tracker-4omi.onrender.com/ws?user_id=1&role=merchant&merchant_id=1&package_id=123"
   ```

## ⚠️ Important Notes

- **Only `on_the_way` status** shows live location (as per requirements)
- **Merchants** can only see their own package locations
- **Office users** can see all rider locations (in web dashboard at `/office/map`)
- Use `wss://` (not `ws://`) for HTTPS connections

## 🔍 Troubleshooting

### WebSocket not connecting
- ✅ Check WebSocket URL is correct: `wss://location-tracker-4omi.onrender.com`
- ✅ Verify Go server is running on Render (check dashboard)
- ✅ Check package status is `on_the_way`
- ✅ Check user has merchant role and merchant_id

### Location not updating
- ✅ Check Go server logs on Render dashboard
- ✅ Verify Laravel is sending updates to Go server
- ✅ Check `GO_WEBSOCKET_URL` in Laravel `.env` on Render

### Connection drops
- ⚠️ Normal on Render free tier (spins down after 15 min inactivity)
- ✅ Auto-reconnect handles this automatically
- ⚠️ First connection after sleep takes ~30 seconds (cold start)

## 📊 Status Rules

- **Merchants**: Can see rider location ONLY when package status = `on_the_way`
- **Office**: Can always see all rider locations (web dashboard)

## 🚀 Next Steps

1. Update Laravel `.env` on Render with `GO_WEBSOCKET_URL`
2. Test with a real package that has status `on_the_way`
3. Monitor Go server logs on Render dashboard
4. Check Flutter app logs for WebSocket connection status
