# macOS 安卓模拟器

`macOS 安卓模拟器` 是一个面向 Apple Silicon Mac 的原生安卓模拟器管理平台。它使用官方 Android Emulator 作为运行后端，并在 macOS 原生 App 中提供实例管理、多开、机型模拟、APK 安装、自动横竖屏和点击器脚本能力。

## 当前能力

- macOS 原生 SwiftUI 界面，支持简体中文和英文切换。
- 自动定位 Android SDK：`ANDROID_HOME`、`ANDROID_SDK_ROOT`、`~/Library/Android/sdk`。
- SDK 诊断：`adb`、`emulator`、`avdmanager`、`sdkmanager`。
- 默认实例目录：`/Volumes/DDISK/macOS/Android/avd`。
- 默认 Android 系统镜像：Android 15 / API 35 / Google APIs / arm64-v8a。
- 可选游戏兼容镜像：Android 9 / API 28 / Google APIs / arm64-v8a。
- 默认新实例数据盘：50 GB。
- 实例列表、创建、复制、删除、启动、停止。
- 主流品牌机型预设：HUAWEI、SAMSUNG、Google、Xiaomi、Redmi、OPPO、vivo、OnePlus、HONOR。
- 每实例虚拟身份：IMEI、IMSI、Android ID、serial、Wi-Fi MAC、手机号。
- 复制实例时随机生成机型和虚拟身份。
- 分辨率、DPI、FPS、CPU、内存、磁盘容量、Root、ADB 配置。
- 性能档位包含 `lean`、`balanced`、`performance`、`game`；`game` 档使用 3 GB 内存、2 核、Host GPU 和 384 MB VM heap，对标 LDPlayer/MuMu 级内存占用。禁用不需要的传感器和 GPS 以进一步降低主机内存开销。
- 安卓系统设置入口：语言、无障碍、电源优化、安卓设置页。
- 网络修复入口：关闭飞行模式、开启 Wi-Fi/移动数据，并使用 emulator 全速网络参数启动。
- 自动应用方向规则：例如 `com.u1game.cabalm` 自动横屏，桌面自动竖屏。
- 点击器和宏脚本：截图录制点击、录制滑动轨迹、等待、保存 JSON 脚本、循环播放、速度倍率。
- 大 APK 安装：对 3 GB+ 超大 APK 使用 30 分钟超时，ADB streaming 失败时自动回退普通安装和 `-t` 标志安装。
- CLI 工具 `mosctl`，方便自动化和排查。

## 重要说明

本项目不是从零实现 Android 虚拟化内核。它包装和编排官方 Android Emulator，所以 QEMU、ART、GPU 虚拟化、Google APIs 和系统镜像仍由 Android SDK 提供。

官方 Android Emulator 可以直接控制分辨率、DPI、FPS、serial、手机号、磁盘容量、Root/ADB 参数等。完整伪装所有 Android API 返回的 IMEI 和 `ro.product.*` 需要后续自定义系统镜像、Root 模块或框架层补丁。

## 环境要求

- macOS 14+
- Apple Silicon Mac
- Swift 6 toolchain
- Android Studio 或 Android Command-line Tools
- Android SDK 组件：
  - `platform-tools`
  - `emulator`
  - `cmdline-tools`
  - `system-images;android-35;google_apis;arm64-v8a`
  - 可选：`system-images;android-28;google_apis;arm64-v8a`

## 构建和运行

```bash
swift build --product mosctl
.build/debug/mosctl doctor
swift run mos-selftest
scripts/build-app.sh
open .build/macOS.app
```

## 常用命令

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

更多说明见 [docs/usage.zh-CN.md](docs/usage.zh-CN.md)。

## 开源状态

目前还没有选择开源许可证。公开发布前请先确认许可证类型。见 [LICENSE_NOTICE.md](LICENSE_NOTICE.md)。
