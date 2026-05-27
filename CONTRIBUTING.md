# Contributing

Thanks for your interest in improving macOS Android Emulator.

## Development Checks

Run these before submitting changes:

```bash
swift build --product mosctl
swift build --product MOSMacApp
swift run mos-selftest
```

## Project Boundaries

- Keep Android SDK orchestration in `MOSCore`.
- Keep macOS UI state in `MOSMacApp`.
- Do not commit AVD images, APK files, build outputs, or user data.
- Prefer explicit diagnostics when Android SDK tools are missing.

## Documentation

When adding a user-facing feature, update both Chinese and English docs.
