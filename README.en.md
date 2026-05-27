# macOS Android Emulator

`macOS Android Emulator` is a native macOS management platform for Android emulator workflows on Apple Silicon Macs. It uses the official Android Emulator as the execution backend and adds a Mac-native experience for instances, device profiles, APK installation, auto rotation, and macro playback.

## Features

- Native SwiftUI macOS app with Simplified Chinese and English UI.
- Android SDK discovery via `ANDROID_HOME`, `ANDROID_SDK_ROOT`, and `~/Library/Android/sdk`.
- Diagnostics for `adb`, `emulator`, `avdmanager`, and `sdkmanager`.
- Default instance storage: `/Volumes/DDISK/macOS/Android/avd`.
- Default Android image: Android 15 / API 35 / Google APIs / arm64-v8a.
- Optional game compatibility image: Android 9 / API 28 / Google APIs / arm64-v8a.
- Default new-instance data disk: 50 GB.
- Instance list, create, copy, delete, boot, and stop.
- Device presets for HUAWEI, SAMSUNG, Google, Xiaomi, Redmi, OPPO, vivo, OnePlus, and HONOR.
- Per-instance virtual identity: IMEI, IMSI, Android ID, serial, Wi-Fi MAC, and phone number.
- Randomized model and identity when copying instances.
- Display, DPI, FPS, CPU, memory, disk, Root, and ADB settings.
- Runtime profiles include `lean`, `balanced`, `performance`, and `game`; `game` uses 3 GB RAM, 4 cores, Host GPU, and a 512 MB VM heap.
- Android settings shortcuts: language, accessibility, battery optimization, and settings.
- Network repair shortcut: disables airplane mode, enables Wi-Fi/mobile data, and boots the emulator with full-speed network parameters.
- App-based auto rotation, for example `com.u1game.cabalm` landscape and launcher portrait.
- Clicker and macro scripts: screenshot-based tap recording, swipe recording, waits, JSON save/load, repeat playback, and speed control.
- Large APK installation with real `/data` space checks and automatic fallback when streaming install fails.
- `mosctl` CLI for automation and support.

## Important Scope Note

This project is not a clean-room Android virtualization engine. It orchestrates the official Android Emulator, so QEMU, ART, GPU virtualization, Google APIs, and Android system images are still provided by the Android SDK.

The official Android Emulator can directly control display, DPI, FPS, serial, phone number, disk size, Root/ADB options, and launch parameters. Full spoofing of every Android API for IMEI and read-only `ro.product.*` values requires future custom system images, root modules, or framework-level injection.

## Requirements

- macOS 14+
- Apple Silicon Mac
- Swift 6 toolchain
- Android Studio or Android Command-line Tools
- Android SDK components:
  - `platform-tools`
  - `emulator`
  - `cmdline-tools`
  - `system-images;android-35;google_apis;arm64-v8a`
  - Optional: `system-images;android-28;google_apis;arm64-v8a`

## Build

```bash
swift build --product mosctl
.build/debug/mosctl doctor
swift run mos-selftest
scripts/build-app.sh
open .build/macOS.app
```

## Common Commands

```bash
.build/debug/mosctl licenses
.build/debug/mosctl install-image 'system-images;android-35;google_apis;arm64-v8a'
.build/debug/mosctl install-image 'system-images;android-28;google_apis;arm64-v8a'
.build/debug/mosctl list
.build/debug/mosctl create macos_phone_01 --profile game --disk 51200 --force
.build/debug/mosctl boot macos_phone_01 --no-snapshot
.build/debug/mosctl repair-network auto
.build/debug/mosctl install-apk auto /absolute/path/app.apk
.build/debug/mosctl apply-orientation auto macos_phone_01
.build/debug/mosctl macro-list
.build/debug/mosctl macro-play auto game_macro --repeat 10 --speed 1.2
```

See [docs/usage.en.md](docs/usage.en.md) for details.

## License Status

No open-source license has been selected yet. Confirm the license before publishing a public release. See [LICENSE_NOTICE.md](LICENSE_NOTICE.md).

## Disclaimer

This is an open-source community project, not affiliated with Google, Android, MuMu, LDPlayer, BlueStacks, or any commercial Android emulator.

- This software is provided "as is" without warranty of any kind.
- Users are solely responsible for any consequences of using this software.
- This project does not collect any user data.
- Usage of Android SDK and its components is subject to Google's license agreements.

## License

Source code is released under the MIT License. See [LICENSE](LICENSE).

Android SDK, system images, and the emulator engine are provided by Google and subject to their own license agreements.
