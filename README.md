# macOS Android Emulator

A native macOS Android emulator management platform for Apple Silicon Macs.

- 中文说明: [README.zh-CN.md](README.zh-CN.md)
- English guide: [README.en.md](README.en.md)
- Architecture: [docs/architecture.md](docs/architecture.md)
- App Store readiness: [中文](docs/app-store-readiness.zh-CN.md) / [English](docs/app-store-readiness.en.md)
- Usage: [中文](docs/usage.zh-CN.md) / [English](docs/usage.en.md)

This project orchestrates the official Android SDK Emulator, AVD Manager, SDK Manager, and ADB. It is not a clean-room Android virtualization engine. The goal is to provide a polished Mac user experience for instance management, multi-open workflows, device profiles, APK installation, storage tuning, automatic app rotation, and macro playback.

The current default Android image target is:

```text
system-images;android-35;google_apis;arm64-v8a
Android 15 / API 35
```

An optional compatibility image is supported for older game SDKs:

```text
system-images;android-28;google_apis;arm64-v8a
Android 9 / API 28
```

## Quick Start

```bash
swift build --product mosctl
.build/debug/mosctl doctor
swift run mos-selftest
scripts/build-app.sh
open .build/macOS.app
```

## License

No open-source license has been selected yet. See [LICENSE_NOTICE.md](LICENSE_NOTICE.md) before publishing a public release.
