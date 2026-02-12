# How to Build APK Files for Flutter Apps

Complete guide for building APK files for `ok_delivery` (merchant app) and `rider_v2_app` (rider app).

## Prerequisites

1. **Flutter SDK** installed and configured
   - Check: `flutter doctor`
   - Should show no critical issues

2. **Android SDK** installed
   - Android Studio or Android SDK Command-line Tools
   - Set `ANDROID_HOME` environment variable

3. **Java JDK** (version 11 or higher)
   - Check: `java -version`

## Quick Build Commands

### For Merchant App (ok_delivery)

```bash
cd ok_delivery
flutter clean
flutter pub get
flutter build apk
```

**Output location:** `ok_delivery/build/app/outputs/flutter-apk/app-release.apk`

### For Rider App (rider_v2_app)

```bash
cd rider_v2_app
flutter clean
flutter pub get
flutter build apk
```

**Output location:** `rider_v2_app/build/app/outputs/flutter-apk/app-release.apk`

---

## Step-by-Step Guide

### Step 1: Navigate to App Directory

**For Merchant App (ok_delivery):**
```powershell
cd C:\Users\HP\OneDrive\Desktop\deli\ok_delivery
```

**For Rider App (rider_v2_app):**
```powershell
cd C:\Users\HP\OneDrive\Desktop\deli\rider_v2_app
```

### Step 2: Clean Previous Builds (Optional but Recommended)

```bash
flutter clean
```

This removes old build artifacts and ensures a fresh build.

### Step 3: Get Dependencies

```bash
flutter pub get
```

This downloads all required packages from `pubspec.yaml`.

### Step 4: Build APK

#### Option A: Release APK (Recommended for Distribution)

```bash
flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

**Size:** Optimized, smaller file size
**Use:** For distribution to users

#### Option B: Debug APK (For Testing)

```bash
flutter build apk --debug
```

**Output:** `build/app/outputs/flutter-apk/app-debug.apk`

**Size:** Larger, includes debug symbols
**Use:** For testing and development

#### Option C: Split APKs by ABI (Smaller File Size)

```bash
flutter build apk --split-per-abi
```

**Output:** Multiple APKs:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

**Size:** Smaller individual files
**Use:** For Google Play Store (auto-selects correct one)

---

## Build Variants

### Build with Specific Version

```bash
flutter build apk --build-name=1.0.0 --build-number=1
```

### Build for Specific Target

```bash
# Build only for ARM64 (most modern devices)
flutter build apk --target-platform android-arm64

# Build only for ARM32 (older devices)
flutter build apk --target-platform android-arm
```

---

## Troubleshooting

### Error: "Gradle build failed"

**Solution:**
1. Check Java version: `java -version` (should be 11+)
2. Update Gradle: Edit `android/gradle/wrapper/gradle-wrapper.properties`
3. Clean and rebuild:
   ```bash
   flutter clean
   cd android
   ./gradlew clean
   cd ..
   flutter build apk
   ```

### Error: "SDK location not found"

**Solution:**
1. Set `ANDROID_HOME` environment variable:
   ```powershell
   # Windows PowerShell
   $env:ANDROID_HOME = "C:\Users\YourName\AppData\Local\Android\Sdk"
   ```
2. Or create `android/local.properties`:
   ```
   sdk.dir=C:\\Users\\YourName\\AppData\\Local\\Android\\Sdk
   ```

### Error: "Keystore file not found" (For Signed APK)

**Solution:**
- For testing, use debug APK (no keystore needed)
- For release, create a keystore first (see "Signing APK" section)

### Build Takes Too Long

**Solution:**
- Use `--release` flag (faster than debug)
- Close other applications
- Ensure sufficient disk space

---

## Signing APK (For Release)

### Step 1: Create Keystore

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Note:** Replace `~/upload-keystore.jks` with your desired path.

### Step 2: Configure Signing

Create `android/key.properties`:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=path/to/your/keystore.jks
```

### Step 3: Update build.gradle

Edit `android/app/build.gradle.kts` to include signing config (see Flutter documentation).

### Step 4: Build Signed APK

```bash
flutter build apk --release
```

---

## Installing APK on Device

### Method 1: Using ADB (Android Debug Bridge)

1. Enable **Developer Options** on your Android device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times

2. Enable **USB Debugging**:
   - Settings → Developer Options → USB Debugging

3. Connect device via USB

4. Install APK:
   ```bash
   adb install app-release.apk
   ```

### Method 2: Direct Transfer

1. Copy APK to device (via USB, email, or cloud storage)
2. Open file manager on device
3. Tap the APK file
4. Allow installation from unknown sources if prompted
5. Tap "Install"

---

## Build Scripts (Optional)

### Windows PowerShell Script

Create `build-apk.ps1` in app directory:

```powershell
# Build APK Script
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "Building release APK..." -ForegroundColor Green
flutter build apk --release

Write-Host "APK built successfully!" -ForegroundColor Green
Write-Host "Location: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Cyan
```

**Usage:**
```powershell
.\build-apk.ps1
```

### Batch Script

Create `build-apk.bat`:

```batch
@echo off
echo Cleaning previous builds...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building release APK...
flutter build apk --release

echo.
echo APK built successfully!
echo Location: build\app\outputs\flutter-apk\app-release.apk
pause
```

**Usage:**
```cmd
build-apk.bat
```

---

## File Sizes

Typical APK sizes:
- **Debug APK:** 50-100 MB
- **Release APK:** 15-40 MB
- **Split APK (per ABI):** 10-20 MB each

---

## Next Steps After Building

1. **Test APK** on a real device
2. **Share APK** with testers
3. **Upload to Google Play Store** (if publishing)
4. **Distribute via direct download** (for internal use)

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `flutter build apk` | Build release APK |
| `flutter build apk --debug` | Build debug APK |
| `flutter build apk --split-per-abi` | Build split APKs |
| `flutter clean` | Clean build cache |
| `flutter pub get` | Get dependencies |

---

## Tips

1. **Always test** the APK on a real device before distribution
2. **Use release build** for production (smaller, optimized)
3. **Keep keystore safe** - you'll need it for updates
4. **Update version** in `pubspec.yaml` before each release
5. **Check file size** - optimize if too large

---

## Common Build Locations

After building, APK files are located at:

- **Merchant App (ok_delivery):** `ok_delivery/build/app/outputs/flutter-apk/app-release.apk`
- **Rider App (rider_v2_app):** `rider_v2_app/build/app/outputs/flutter-apk/app-release.apk`

---

## Need Help?

- Check Flutter documentation: https://docs.flutter.dev/deployment/android
- Run `flutter doctor` to diagnose issues
- Check build logs for specific errors

