# LocalWave

> An offline music player with a Spotify-inspired dark UI. Plays local media files from your phone's storage — no internet required.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.x + Dart |
| State Management | Riverpod 2.x |
| Audio Playback | `just_audio` + `audio_service` |
| Media Scanning | `on_audio_query` |
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
- Full device media scan via Android MediaStore
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
├── main.dart                          ← Entry point, audio service init
├── app.dart                           ← MaterialApp with splash + permission gate
├── core/
│   ├── theme/                         ← Colors, text styles, dark theme
│   ├── constants.dart                 ← App-wide constants
│   └── utils/                         ← Duration formatter, extensions
├── data/
│   ├── models/                        ← Song, Album, Artist, Playlist, LyricLine, PlaybackHistory
│   ├── datasources/                   ← SQLite DB, media scanner, LRC parser
│   └── repositories/                  ← Media, Playlist, Favorites repos
├── services/
│   ├── audio_handler.dart             ← BaseAudioHandler (just_audio + audio_service)
│   ├── audio_player_service.dart      ← High-level playback API
│   ├── lyrics_sync_service.dart       ← Real-time lyrics line detection
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

**56 Dart files, ~6,300 lines of code.**

---

## Setup & Run

### Prerequisites

1. **Flutter SDK 3.16+** — [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Android Studio** or **VS Code** with Flutter/Dart plugins
3. **Android device** or emulator (API 26+)

### Steps

```bash
# 1. Navigate to project
cd C:\mobile

# 2. Generate native platform files (Android, iOS)
flutter create . --org com.localwave

# 3. Install dependencies
flutter pub get

# 4. Run on connected device
flutter run
```

### First Launch

1. The app shows a splash screen, then a **permission gate**
2. Tap **"Allow Access"** to grant audio storage permission
3. The app auto-scans your device for music files
4. Your library appears on the Home screen

---

## Build APK

### Debug APK (for testing)

```bash
flutter build apk --debug
```

**Output location:**
```
C:\mobile\build\app\outputs\flutter-apk\app-debug.apk
```

### Release APK (for distribution)

```bash
flutter build apk --release
```

**Output location:**
```
C:\mobile\build\outputs\apk\release\app-release.apk
```

### Split APKs by ABI (smaller size)

```bash
flutter build apk --split-per-abi
```

**Output locations:**
```
C:\mobile\build\outputs\apk\release\app-armeabi-v7a-release.apk
C:\mobile\build\outputs\apk\release\app-arm64-v8a-release.apk
C:\mobile\build\outputs\apk\release\app-x86_64-release.apk
```

### App Bundle (for Play Store)

```bash
flutter build appbundle
```

**Output location:**
```
C:\mobile\build\app\outputs\bundle\release\app-release.aab
```

---

## Signing the Release APK

For a signed release APK:

```bash
# Generate a keystore (one-time)
keytool -genkey -v -keystore C:\mobile\android\app\localwave-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias localwave

# Build with release signing
flutter build apk --release
```

Or configure `android/app/build.gradle` with your signing config.

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
├── song.lrc          ← lyrics file
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

| Package | Purpose |
|---|---|
| `just_audio` | Audio playback engine |
| `audio_service` | Background playback, notification controls |
| `on_audio_query` | Device media store scanning |
| `sqflite` | Local SQLite database |
| `flutter_riverpod` | State management |
| `flutter_animate` | Animations and transitions |
| `palette_generator` | Dynamic color extraction |
| `permission_handler` | Runtime permissions |
| `google_fonts` | Inter font |
| `uuid` | Unique ID generation |

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
