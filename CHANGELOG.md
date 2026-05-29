# Changelog

## Unreleased

### Game Performance And Compatibility
- Persist per-instance memory, CPU core count, and GPU mode overrides.
- Added `Software` GPU mode to the macOS performance UI for games that fail on Host GPU.
- Restored 32-bit LCD color depth and common sensors/GPS for better 3D game compatibility.
- Network repair now clears guest proxy, Private DNS, IPv6 addresses, and `ipv6proxy` state to avoid VPN/IPv6 routing stalls for mainland game servers.
- Game profile uses **3GB/2cores**, Host GPU, and **512MB** VM heap by default.
- App auto-rotation now resets `wm size`/density overrides and lets the game Activity own the landscape surface, avoiding rotated portrait content inside a landscape emulator window.

## v0.2.0 - 2026-05-28

### Memory Optimization
- Game profile: 6GB/4cores → **3GB/2cores** (matches LDPlayer/MuMu efficiency)
- Lean profile: 2GB → **1.5GB**
- Balanced profile: 3GB → **2GB**
- Performance profile: 4GB → **3GB**
- VM heap sizes optimized per profile

### Large APK Install Fix
- APKs over 500MB automatically use push + pm install strategy
- Avoids ADB direct install timeout for 3.6GB+ game APKs
- Tested with 新惊天动地 (CabalM) 3.6GB APK on Android 9

### Emulator Launch
- Removed incorrect `-partition-size` flag from config-based launch
- Data disk size is now correctly controlled by AVD config `disk.dataPartition.size`
- Both instances (Android 9 / Android 15) verified with 50GB data disks

### Instance Data Disk Fix
- Fixed qcow2 overlay not expanding when `disk.dataPartition.size` config changes
- `mosctl rebuild-data` correctly removes old overlays for emulator recreation

## v0.1.0 - 2026-05-27

### Initial Release
- macOS native SwiftUI app with Chinese/English support
- Android 15 (API 35) and Android 9 (API 28) system images
- Instance management: create, copy, delete, boot, stop
- Device brand presets: HUAWEI, SAMSUNG, Google, Xiaomi, Redmi, OPPO, vivo, OnePlus, HONOR
- Per-instance virtual identity: IMEI, IMSI, Android ID, serial, Wi-Fi MAC, phone number
- Resolution, DPI, FPS, CPU, memory, disk, Root, ADB configuration
- Auto orientation: landscape for games, portrait for desktop
- Macro recorder: click recording, swipe gestures, wait, JSON script save/load, loop playback
- System settings: language, accessibility, battery optimization
- CLI tool `mosctl`
