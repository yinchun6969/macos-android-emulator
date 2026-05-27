# Usage Guide

## 1. Environment Check

```bash
.build/debug/mosctl doctor
```

Create or boot instances only after all required tools report `[OK]`.

## 2. Install the Android Image

```bash
.build/debug/mosctl licenses
.build/debug/mosctl install-image 'system-images;android-35;google_apis;arm64-v8a'
```

The default Android version is Android 15 / API 35.

If a game SDK has device-identifier, compatibility, or startup issues on Android 15, install the Android 9 compatibility image:

```bash
.build/debug/mosctl install-image 'system-images;android-28;google_apis;arm64-v8a'
```

## 3. Create an Instance

```bash
.build/debug/mosctl create macos_phone_01 --profile game --disk 51200 --force
```

The default new-instance data disk is 50 GB. The app displays disk size in GB.

For an Android 9 compatibility instance:

```bash
.build/debug/mosctl create macos_game_a9 --package 'system-images;android-28;google_apis;arm64-v8a' --profile game --disk 51200 --force
```

## 4. Boot an Instance

```bash
.build/debug/mosctl boot macos_phone_01 --no-snapshot
```

In the app, select an instance on the left and click Boot.

After boot, run network repair once, or use the Repair Network button in the app:

```bash
.build/debug/mosctl repair-network auto
```

## 5. Install APKs

Recommended app flow:

1. Open the Data tab.
2. Choose an APK.
3. Click Install APK.
4. For large games, click Check Storage first to verify Android `/data` free space.

CLI:

```bash
.build/debug/mosctl install-apk auto /absolute/path/game.apk
```

## 6. Auto Rotation

Open the System tab:

- Enable Auto App Rotation.
- Add landscape package names, for example:

```text
com.u1game.cabalm
```

The app monitors the foreground package:

- Matching packages switch to landscape.
- Launcher and other apps return to portrait.

Apply once from CLI:

```bash
.build/debug/mosctl apply-orientation auto macos_phone_01
```

## 7. Game Compatibility Notes

- Use the `game` runtime profile for mobile games.
- If black screen or ANR appears, disable Root and cold boot: `set-config <name> --no-root --profile game --disk 51200`.
- Android 15 restricts normal apps from reading IMEI/device identifiers; older game SDKs that depend on those APIs may work better on the Android 9/API 28 compatibility image.
- Some ad, analytics, or one-tap-login DNS failures may not block the main game. Use the actual game screen and logcat together.

## 8. Clicker And Macro Scripts

Open the Clicker tab:

1. Refresh Screen.
2. Select Record Tap or Record Swipe.
3. Click or drag on the screenshot preview.
4. Add Wait steps as needed.
5. Set repeat count and playback speed.
6. Save Script.
7. Play Script.

Scripts are stored as JSON:

```text
/Volumes/DDISK/macOS/Macros
```

CLI playback:

```bash
.build/debug/mosctl macro-list
.build/debug/mosctl macro-play auto game_macro --repeat 10 --speed 1.2
```

## 9. Disk Expansion Notes

Changing the disk value updates the instance configuration. For existing instances, the Android ext4 filesystem may not automatically grow. If a game reports low storage:

1. Click Check Storage in the Data tab.
2. Save a larger disk size.
3. Stop the instance.
4. Rebuild the data disk or use a future expansion tool.

Rebuilding backs up the old data disk, but the instance will initialize with a fresh Android data partition.
