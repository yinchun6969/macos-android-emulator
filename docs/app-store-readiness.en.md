# App Store Readiness

The project is currently best suited as an open-source developer tool. Shipping it on the Mac App Store requires additional productization and review work.

## Current Risks

1. External Android SDK dependency

   The app currently invokes `adb`, `emulator`, `avdmanager`, and `sdkmanager` installed on the user's machine. Mac App Store sandboxing restricts access to external executables, external drives, and user directories.

2. External instance storage

   The default instance location is `/Volumes/DDISK/macOS/Android/avd`. A sandboxed app needs user-granted access, security-scoped bookmarks, or a container-based storage model.

3. Large images and payloads

   Android system images, AVD data disks, and APK files are large and should not be bundled in the App Store app or in the repository.

4. Root, ADB, and automation features

   Root, ADB, macro scripts, and automated clicking need clear user-facing explanations. They should not be positioned as a way to bypass security controls or abuse services.

5. Google component licensing

   Google APIs system images are provided by the Android SDK. Do not bundle Google system images directly in the repository or app package.

## Recommended Path

### Stage 1: Open-Source Developer Build

- Publish source and documentation on GitHub.
- Users install Android Studio / Android SDK themselves.
- Provide build scripts and diagnostics.
- Do not bundle system images, APKs, or AVD data disks.

### Stage 2: Developer ID Notarized Build

- Sign with Developer ID.
- Notarize with Apple.
- Distribute as DMG or ZIP.
- Continue to rely on a user-installed Android SDK.

### Stage 3: Mac App Store Evaluation

- Move writable data into a container or App Group.
- Add user-authorized Android SDK and external-drive path selection.
- Review sandbox entitlements.
- Remove or isolate high-risk automation features if required.

## Pre-Submission Checklist

- [ ] Choose an open-source license.
- [ ] Set a production Bundle ID.
- [ ] Prepare app icon and screenshots.
- [ ] Prepare privacy disclosures.
- [ ] Provide Android SDK installation onboarding.
- [ ] Handle sandboxed file access.
- [ ] Sign and notarize.
- [ ] Explain that macro/game automation is user-controlled and user-responsible.
