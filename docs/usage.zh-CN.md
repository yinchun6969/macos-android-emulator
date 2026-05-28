# 使用说明

## 1. 环境检查

```bash
.build/debug/mosctl doctor
```

所有项目显示 `[OK]` 后再创建或启动实例。

## 2. 安装 Android 镜像

```bash
.build/debug/mosctl licenses
.build/debug/mosctl install-image 'system-images;android-35;google_apis;arm64-v8a'
```

默认系统版本是 Android 15 / API 35。

如果游戏 SDK 在 Android 15 上出现设备标识权限、兼容性或启动问题，可以安装 Android 9 兼容镜像：

```bash
.build/debug/mosctl install-image 'system-images;android-28;google_apis;arm64-v8a'
```

## 3. 创建实例

```bash
.build/debug/mosctl create macos_phone_01 --profile game --disk 51200 --force
```

默认新实例数据盘是 50 GB。界面中以 GB 展示。

需要 Android 9 兼容实例时：

```bash
.build/debug/mosctl create macos_game_a9 --package 'system-images;android-28;google_apis;arm64-v8a' --profile game --disk 51200 --force
```

## 4. 启动实例

```bash
.build/debug/mosctl boot macos_phone_01 --no-snapshot
```

如果使用 App，选择左侧实例后点击「启动」。

启动后可执行一次网络修复，App 中也有「修复网络」按钮：

```bash
.build/debug/mosctl repair-network auto
```

## 5. 安装 APK

推荐使用 App 的「数据」页：

1. 点击「选择 APK」。
2. 点击「安装 APK」。
3. 如果是大型游戏包，先点击「检查真实空间」确认安卓内部 `/data` 有足够剩余空间。

命令行：

```bash
.build/debug/mosctl install-apk auto /absolute/path/game.apk
```

## 6. 自动横竖屏

进入「系统」页：

- 打开「应用自动横屏」。
- 在「横屏应用包名」中填写需要横屏的包名，例如：

```text
com.u1game.cabalm
```

自动方向规则会监听前台应用：

- 命中横屏包名时切横屏。
- 回到桌面或其他应用时恢复竖屏。

命令行手动应用一次：

```bash
.build/debug/mosctl apply-orientation auto macos_phone_01
```

## 7. 游戏兼容建议

- 手游优先使用 `game` 性能档位。
- 如遇黑屏或 ANR，先关闭 Root，再冷启动：`set-config <name> --no-root --profile game --disk 51200`。
- 如果游戏能进入但卡顿，优先尝试 `Host` GPU；如果 `Host` 进入 3D 场景黑屏，再切回 `Software` 兼容模式并把 FPS 降到 30 或 45。
- 如果日志出现 `emuglGLESv2_enc` 的 vertex attribute 错误，通常是官方 Android Emulator 在 Apple Silicon 上的 GLES 翻译层兼容问题，不是 APK、磁盘或资源包缺失。
- 新实例和已保存实例会独立保存内存、核心数和 GPU 模式，切换左侧实例时不会再共用同一套性能参数。
- Android 15 会限制普通应用读取 IMEI/设备号；老游戏 SDK 如依赖这些接口，可尝试 Android 9/API 28 兼容镜像。
- 部分广告、统计、一键登录域名解析失败不一定会阻止主游戏加载，需要以游戏主界面和日志综合判断。

性能优先：

```bash
.build/debug/mosctl set-config macos_game_a9_01 --profile game --memory 3072 --cores 2 --gpu host --fps 60
```

兼容优先：

```bash
.build/debug/mosctl set-config macos_game_a9_01 --profile game --memory 3072 --cores 2 --gpu software --fps 45
```

## 8. 点击器和宏脚本

进入「点击器」页：

1. 点击「刷新截图」。
2. 选择「录制点击」或「录制轨迹」。
3. 在截图区域点击或拖动。
4. 根据需要添加「等待」。
5. 设置循环次数和速度。
6. 点击「保存脚本」。
7. 点击「播放脚本」执行。

脚本保存为 JSON：

```text
/Volumes/DDISK/macOS/Macros
```

命令行播放：

```bash
.build/debug/mosctl macro-list
.build/debug/mosctl macro-play auto game_macro --repeat 10 --speed 1.2
```

## 9. 磁盘扩容说明

界面中修改磁盘容量会更新实例配置。对于已经创建并运行过的旧实例，Android 内部 ext4 文件系统不一定会自动扩容。遇到游戏提示空间不足时：

1. 在「数据」页点击「检查真实空间」。
2. 如果 `/data` 剩余空间不足，先保存更大的磁盘容量。
3. 停止实例。
4. 使用「重建数据盘」或后续扩容工具处理旧数据盘。

重建数据盘会备份旧数据盘，但会让当前实例内已安装应用重新初始化。

## 安装 APK

小文件（< 500MB）直接使用 `adb install`。

大文件（3GB+ 游戏 APK）自动采用两步策略：
1. `adb push` 将 APK 推送到 `/data/local/tmp/`
2. `pm install -r -g` 从设备本地安装

此方案避免了 ADB 直连超时问题，对 3.6GB 级别的游戏 APK（如新惊天动地）安装成功率接近 100%。

也可以用 CLI 手动安装：
```bash
mosctl install-apk auto /path/to/game.apk
```

## 内存优化

各档位内存配置（对标 LDPlayer/MuMu 级别）：

| 档位 | 内存 | 核心 | VM Heap | GPU |
|------|------|------|---------|-----|
| lean | 1.5 GB | 2 | 128 MB | swiftshader |
| balanced | 2 GB | 2 | 192 MB | auto |
| performance | 3 GB | 3 | 256 MB | host |
| game | 3 GB | 2 | 512 MB | host |

额外优化措施：
- 性能页的内存、核心数、GPU 模式按实例保存
- `Host` GPU 性能最好，`Software` GPU 兼容性更高但会更卡
- 保持 32-bit LCD 色深，避免部分 3D 游戏贴图和后处理异常
- 保留陀螺仪、加速度计、GPS 等常用传感器，避免游戏 SDK 误判设备能力
- 禁用音频输入输出
- 禁用前后摄像头
