# Aryan's Surfer (Flutter + Flame)

A lightweight, no-external-assets, 3-lane endless runner inspired by Subway Surfers.
Swipe left/right to change lanes, up to jump, down to slide. Collect coins, dodge colorful obstacles,
and chase your high score. Built with Flame, fully customizable.

## Quick Start

1) Ensure Flutter SDK is installed (Flutter 3.x+).  
2) Open a terminal:

```bash
cd aryans_surfer
flutter pub get
flutter run    # to test on device/emulator
```

## Build an APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Rename / Branding

- App name is set to **Aryan's Surfer** in `main.dart`.  
- Package name can be changed via `applicationId` in `android/app/build.gradle` or with `flutter create --org com.yourname .` on a fresh project.

## Files

- `lib/game/aryans_surfer_game.dart` — core game loop, spawners, overlays (HUD/Pause/GameOver).
- `lib/components/player.dart` — Player + basic physics + collisions, and also Obstacle/Coin classes to keep imports simple.
- `lib/components/obstacle.dart` & `lib/components/coin.dart` — just re-exports for cleaner imports.
- `pubspec.yaml` — dependencies (Flame, Google Fonts).

## Customize

- Tweak `laneGap`, `gameSpeed`, colors, sizes, spawn rates in `AryansSurferGame`.
- Replace rectangles with sprites by adding images under `assets/` and using `SpriteComponent`.
- Add power-ups (shield/magnet/2x score) by creating new Components similar to `Coin` and handling collisions in `Player.onCollision`.

## Notes

- This project uses simple shapes (no images) so it runs out-of-the-box and looks clean. You can add your own art later.
- This is an **original** template, not a clone of any commercial game assets or code.
