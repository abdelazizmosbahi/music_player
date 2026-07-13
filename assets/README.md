# LocalWave Assets

## Generating App Icon

1. Place your icon PNG at `assets/icon/app_icon.png` (1024x1024)
2. Place your foreground icon at `assets/icon/app_icon_foreground.png` (1024x1024, transparent background)
3. Run: `dart run flutter_launcher_icons`

## Generating Splash Screen

1. Place your logo at `assets/splash/splash_logo.png` (512x512 recommended)
2. Run: `dart run flutter_native_splash:create`

## Design Guidelines for Icon

- Use the green accent color (#1ED760) for the waveform/play button
- Dark background (#121212)
- Keep it simple — a stylized waveform + play triangle works well
- Test at all sizes: 48x48 (notification), 72x72 (launcher), 108x108 (adaptive)
