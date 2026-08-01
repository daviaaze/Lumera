# Lumera Modifications for Homelab Stremio Server

## Summary of Changes

### 1. Streaming Server Integration

**Files Modified:**
- `app/src/main/java/com/lumera/app/data/model/ProfileEntity.kt`
- `app/src/main/java/com/lumera/app/di/DatabaseModule.kt`
- `app/src/main/java/com/lumera/app/ui/settings/SettingsViewModel.kt`
- `app/src/main/java/com/lumera/app/ui/settings/SettingsSubScreens.kt`
- `app/src/main/java/com/lumera/app/MainActivity.kt`
- `app/src/main/java/com/lumera/app/di/NetworkModule.kt`

**Files Created:**
- `app/src/main/java/com/lumera/app/data/model/stremio/IntroSegment.kt`
- `app/src/main/java/com/lumera/app/data/remote/StremioServerApi.kt`
- `app/src/main/java/com/lumera/app/data/repository/IntroRepository.kt` (modified)

### 2. How It Works

#### Streaming Server URL Setting
- Added `streamingServerUrl` field to `ProfileEntity` (user-configurable)
- Added UI in Settings → Playback → "Streaming Server" section
- When configured, torrent streams use `{serverUrl}/{info_hash}/{file_idx}` directly
- Falls back to local TorrServer when not configured

#### Skip Intro
- Added `skipIntroSource` setting: "introdb", "server", or "off"
- When "server" is selected, intro detection uses our stremio server's `/intro/{info_hash}/{file_idx}` endpoint
- Server runs ffmpeg silencedetect in background
- Client polls for results and updates SkipSegmentInfo dynamically

### 3. Database Migration
- Added `MIGRATION_43_44` for new columns
- Columns: `streamingServerUrl TEXT`, `skipIntroSource TEXT`

### 4. Configuration on the TV
1. Open Lumera → Settings → Playback
2. Scroll to "Streaming Server" section
3. Enter URL: `http://192.168.15.33:8080` (or your stremio server URL)
4. Set "Skip Intro Source" to "Streaming Server"

## Build Instructions

### Prerequisites
- Java JDK 17+
- Android SDK (API 34+)
- Android Studio (recommended)

### Steps
1. Clone the fork: `git clone https://github.com/daviaaze/Lumera.git`
2. Open in Android Studio
3. Sync Gradle
4. Build → Build Bundle(s) / APK(s) → Build APK(s)
5. Install on TV: `adb install app/build/outputs/apk/debug/app-debug.apk`

### Alternative: Command Line
```bash
cd Lumera
./gradlew assembleDebug
```

The APK will be at: `app/build/outputs/apk/debug/app-debug.apk`
