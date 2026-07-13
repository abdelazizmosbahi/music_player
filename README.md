# LocalWave

> An offline music player with a Spotify-inspired dark UI. Plays local media files from your phone's storage — no internet required.

---

## Status

**Builds successfully.** Debug APK is available at:
```
C:\mobile\build\app\outputs\flutter-apk\app-debug.apk
```

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.44.6 + Dart 3.12.2 |
| Android Gradle Plugin | 8.7.3 |
| Kotlin | 2.1.0 |
| State Management | Riverpod 2.x |
| Audio Playback | `just_audio` 0.9.46 + `audio_service` 0.18.19 |
| Media Scanning | `on_audio_query` 2.9.0 |
| Lyrics | Custom `.lrc` parser |
| Local DB | `sqflite` |
| Animations | `flutter_animate` |
| Dynamic Colors | `palette_generator` |
| Min Target | Android 8.0 (API 26) |
| Accent Color | Green `#1ED760` |

---

## Features

### Core Playback
- Play/pause/skip/seek with background playback
- Lock screen + notification media controls
- Shuffle and repeat (off / all / one)
- Queue management: add next, add to queue, drag-to-reorder, swipe-to-remove
- Crossfade and gapless playback support

### Library
- Full device media scan via Android MediaStore (`on_audio_query`)
- Browse by: Songs, Albums, Artists, Playlists
- Album detail with song list
- Artist detail with song list and album count
- Create, rename, and delete playlists
- Add/remove songs from playlists
- Sort songs by title, artist, date added, duration

### Favorites
- Heart toggle on any song tile or Now Playing screen
- Persisted to SQLite database
- "Liked Songs" smart playlist

### Search
- Real-time search across songs, artists, and albums
- Debounced input (300ms)
- Recent search history with clear option
- Browse categories

### Real-Time Synced Lyrics
- Custom `.lrc` file parser (standard format)
- Binary search for active line based on playback position
- Auto-scrolling list with active line highlighted
- Tap any line to seek to that timestamp
- Import `.lrc` files from device

### Now Playing Screen
- Large album art with rounded corners and shadow
- Animated rotating album art while playing
- Song title + artist with marquee overflow
- Seekable progress bar with elapsed/remaining time
- Animated play/pause button (scale morph)
- Animated favorite heart (bounce on toggle)
- Shuffle, previous, play/pause, next, repeat controls
- Lyrics, Share, Queue, EQ bottom actions
- Dynamic background color based on song title hash
- Swipe up from mini player to open

### Mini Player
- Persistent bottom bar above navigation
- Real-time progress bar
- Album art, song info, play/pause, skip
- Swipe up or tap to open full Now Playing
- Slides in with animation when a song starts

### Sleep Timer
- Preset options: 15m, 30m, 45m, 1h, 1.5h, 2h
- Custom time picker
- Live countdown display
- Auto-pauses playback when timer ends
- Remembers last used timer

### Settings
- Crossfade duration slider (0–12s)
- Gapless playback toggle
- Rescan music library
- Clear cache
- Accent color picker (Green, Purple, Blue, Coral, Orange)
- Open source licenses
- Privacy policy

### UI/UX
- Spotify-inspired dark theme (`#121212` background)
- Inter font via Google Fonts
- Hero transitions on album art
- Staggered list entry animations
- Animated page transitions
- Pull-to-refresh on home screen
- Empty state illustrations
- Shimmer loading placeholders

### Permission & Privacy
- First-launch permission gate with clear explanation
- Auto media scan after permission granted
- Settings redirect if permission denied
- All data stays on-device

---

## Architecture

```
lib/
├── main.dart                          ← Entry point, AudioService.init
├── app.dart                           ← MaterialApp with splash + permission gate
├── core/
│   ├── theme/                         ← AppColors, AppTextStyles, AppTheme
│   ├── constants.dart                 ← App-wide constants
│   └── utils/                         ← Duration formatter, extensions
├── data/
│   ├── models/                        ← Song, Album, Artist, Playlist, LyricLine, PlaybackHistory
│   ├── datasources/                   ← SQLite DB, media scanner (on_audio_query), LRC parser
│   └── repositories/                  ← Media, Playlist, Favorites repos
├── services/
│   ├── audio_handler.dart             ← LocalWaveAudioHandler (BaseAudioHandler)
│   ├── audio_player_service.dart      ← High-level playback API
│   ├── lyrics_sync_service.dart       ← Binary-search real-time lyrics sync
│   ├── sleep_timer_service.dart       ← Countdown timer with callback
│   └── dynamic_color_service.dart     ← Palette extraction from album art
├── providers/
│   └── media_provider.dart            ← All Riverpod providers
├── features/
│   ├── main_navigation_shell.dart     ← Bottom nav (Home / Search / Library)
│   ├── permission_gate.dart           ← First-launch permission flow
│   ├── home/                          ← Home screen with recently played
│   ├── search/                        ← Search with debounce + history
│   ├── library/                       ← Tabs: Songs, Albums, Artists, Playlists
│   ├── now_playing/                   ← Full-screen player with all controls
│   ├── lyrics/                        ← Synced lyrics view
│   ├── queue/                         ← Queue management
│   ├── playlists/                     ← Playlist detail + create dialog
│   ├── settings/                      ← App settings
│   ├── sleep_timer/                   ← Sleep timer UI
│   └── splash/                        ← Splash screen
└── shared_widgets/                    ← MiniPlayer, SongTile, AlbumArt, etc.
```

**56 Dart files, ~6,400 lines of code.**

---

## Setup

### Prerequisites

1. **Flutter SDK 3.44+** — https://docs.flutter.dev/get-started/install/windows/mobile
2. **Android SDK 36** + **BuildTools 28.0.3** + **NDK 28.2.13676358**
3. **Android device** or emulator (API 26+)

### First-Time Setup

```bash
cd C:\mobile

# Generate native Android project files
flutter create . --org com.localwave

# Install dependencies
flutter pub get
```

### Important: Patched Dependencies

This project requires two patches to work with the current Android toolchain. These are already applied in the repo:

1. **`on_audio_query_android` namespace** — The plugin's `build.gradle` is missing a `namespace` declaration required by AGP 8.x. Patched at:
   ```
   %PUB_CACHE%\hosted\pub.dev\on_audio_query_android-1.1.0\android\build.gradle
   ```
   Added `namespace 'com.lucasjosino.on_audio_query'` and JVM target 17.

2. **AGP version** — `settings.gradle.kts` uses AGP 8.7.3 (not 9.x) because `on_audio_query_android` hasn't been updated for AGP 9.

If you re-run `flutter pub get` after a cache clear, re-apply patch #1.

### Build APK

```bash
flutter build apk --debug --android-skip-build-dependency-validation
```

> **Note:** `--android-skip-build-dependency-validation` is needed because the project uses AGP 8.7.3 which Flutter 3.44 flags as "soon unsupported." This flag bypasses that check.

---

## APK Output

### Debug APK (for testing)

```bash
flutter build apk --debug --android-skip-build-dependency-validation
```

**Output location:**
```
C:\mobile\build\app\outputs\flutter-apk\app-debug.apk
```

### Release APK (for distribution)

```bash
flutter build apk --release --android-skip-build-dependency-validation
```

**Output location:**
```
C:\mobile\build\app\outputs\flutter-apk\app-release.apk
```

### Split APKs by ABI (smaller size)

```bash
flutter build apk --split-per-abi --android-skip-build-dependency-validation
```

**Output locations:**
```
C:\mobile\build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
C:\mobile\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
C:\mobile\build\app\outputs\flutter-apk\app-x86_64-release.apk
```

### Install via ADB

```bash
adb install C:\mobile\build\app\outputs\flutter-apk\app-debug.apk
```

### App Bundle (for Play Store)

```bash
flutter build appbundle --android-skip-build-dependency-validation
```

**Output location:**
```
C:\mobile\build\app\outputs\bundle\release\app-release.aab
```

---

## Signing the Release APK

```bash
# Generate a keystore (one-time)
keytool -genkey -v -keystore C:\mobile\android\app\localwave-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias localwave

# Build with release signing
flutter build apk --release --android-skip-build-dependency-validation
```

Or configure `android/app/build.gradle.kts` with your signing config.

---

## Generating App Icon & Splash

### App Icon

1. Place a 1024x1024 PNG at `assets/icon/app_icon.png`
2. Run:
   ```bash
   dart run flutter_launcher_icons
   ```

### Splash Screen

1. Place a logo at `assets/splash/splash_logo.png`
2. Run:
   ```bash
   dart run flutter_native_splash:create
   ```

---

## Adding Lyrics

Place `.lrc` files alongside your audio files with the same name:

```
/sdcard/Music/
├── song.mp3
├── song.lrc
├── another_song.flac
├── another_song.lrc
```

### LRC Format

```
[00:12.34]First line of the song
[00:16.02]Second line of the song
[00:20.11]Third line, building up
[00:25.50]Chorus begins here
```

---

## Key Packages

| Package | Version | Purpose |
|---|---|---|
| `just_audio` | 0.9.46 | Audio playback engine |
| `audio_service` | 0.18.19 | Background playback, notification controls |
| `on_audio_query` | 2.9.0 | Device media store scanning |
| `sqflite` | 2.3.x | Local SQLite database |
| `flutter_riverpod` | 2.6.1 | State management |
| `flutter_animate` | 4.x | Animations and transitions |
| `palette_generator` | 0.3.3+7 | Dynamic color extraction |
| `permission_handler` | 11.4.0 | Runtime permissions |
| `google_fonts` | 6.x | Inter font |
| `uuid` | 4.x | Unique ID generation |

---

## Known Issues

- **No app icon yet** — Default Flutter icon. Place your icon at `assets/icon/app_icon.png` and run `dart run flutter_launcher_icons`.
- **No splash logo yet** — Default white splash. Place your logo at `assets/splash/splash_logo.png` and run `dart run flutter_native_splash:create`.
- **`on_audio_query_android` patch** — Requires manual patch to the pub cache (see Setup section) on fresh installs.
- **Palette generator discontinued** — The `palette_generator` package is marked discontinued on pub.dev. Consider migrating to an alternative if it stops receiving updates.

---

## Git History

```
e0d25cd fix: resolve all compilation errors for debug APK build
e27686b feat: LocalWave - offline music player with Spotify-style dark UI
```

---

## Legal

- This app plays **local media files only** — no streaming, no network requests
- All data (playlists, favorites, play history) stored locally in SQLite
- No user data leaves the device
- Spotify-inspired dark UI design — no Spotify brand assets used
- Build your own icon and branding for release

---

## License

MIT License — do whatever you want with it.
