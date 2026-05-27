# 苹果商店上架准备说明

本项目目前适合作为开发者工具和开源项目发布。若要上架 Mac App Store，需要额外完成产品化和审核适配。

## 当前风险

1. Android SDK 外部依赖

   App 当前调用用户机器上的 `adb`、`emulator`、`avdmanager` 和 `sdkmanager`。Mac App Store 沙盒环境会限制对外部可执行文件、外部磁盘和用户目录的访问。

2. 外置磁盘实例目录

   默认实例目录是 `/Volumes/DDISK/macOS/Android/avd`。沙盒 App 需要通过用户授权、书签权限或改用容器目录。

3. 大文件和系统镜像

   Android 系统镜像、AVD 数据盘和游戏 APK 体积很大，不适合直接随 App Store 安装包分发。

4. Root、ADB 和自动化能力

   Root、ADB、宏脚本、自动点击等能力需要在说明中明确用途，避免被误解为绕过安全机制或滥用自动化。

5. Google 组件授权

   Google APIs system image 由 Android SDK 提供。发布时不能把 Google 系统镜像直接打包进仓库或 App。

## 建议路线

### 阶段 1：开源开发者版

- GitHub 发布源码和文档。
- 用户自行安装 Android Studio / Android SDK。
- 提供构建脚本和诊断工具。
- 不捆绑系统镜像、APK、AVD 数据盘。

### 阶段 2：签名公证版

- 使用 Developer ID 签名。
- 做 macOS notarization。
- 发布 DMG 或 ZIP。
- 继续让用户自行安装 Android SDK。

### 阶段 3：Mac App Store 评估版

- 将可写数据迁移到 App Group 或容器目录。
- 实现用户选择 Android SDK 路径和外置盘路径的授权流程。
- 检查 sandbox entitlement。
- 移除或隔离高风险自动化能力，必要时作为非商店版功能。

## 上架前清单

- [ ] 选择开源许可证。
- [ ] 更换正式 Bundle ID。
- [ ] 准备 App 图标和截图。
- [ ] 准备隐私说明。
- [ ] 明确 Android SDK 安装引导。
- [ ] 处理沙盒文件访问。
- [ ] 签名和公证。
- [ ] 编写用户条款，说明宏脚本和游戏自动化由用户自行负责。
