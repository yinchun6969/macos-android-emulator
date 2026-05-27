import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MOSCore

@main
struct MOSMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1100, minHeight: 720)
        }
        .windowStyle(.titleBar)
    }
}

enum AppLanguage: String, CaseIterable {
    case zh
    case en
}

enum MacroRecordMode {
    case tap
    case swipe
}

enum SettingsTab: String, CaseIterable {
    case device
    case display
    case system
    case macro
    case performance
    case data
    case developer
    case global

    var systemImage: String {
        switch self {
        case .device:
            return "iphone"
        case .display:
            return "display"
        case .system:
            return "accessibility"
        case .macro:
            return "cursorarrow.click"
        case .performance:
            return "cpu"
        case .data:
            return "externaldrive"
        case .developer:
            return "chevron.left.forwardslash.chevron.right"
        case .global:
            return "slider.horizontal.3"
        }
    }
}

enum L10n {
    static func text(_ key: String, _ language: AppLanguage) -> String {
        strings[key]?[language] ?? key
    }

    private static let strings: [String: [AppLanguage: String]] = [
        "title": [.zh: "macOS 安卓模拟器", .en: "macOS Android Emulator"],
        "instances": [.zh: "实例", .en: "Instances"],
        "adb": [.zh: "ADB 设备", .en: "ADB Devices"],
        "refresh": [.zh: "刷新", .en: "Refresh"],
        "save": [.zh: "保存", .en: "Save"],
        "create": [.zh: "创建", .en: "Create"],
        "copy": [.zh: "复制", .en: "Copy"],
        "delete": [.zh: "删除", .en: "Delete"],
        "deleteInstance": [.zh: "删除实例", .en: "Delete Instance"],
        "deleteConfirm": [.zh: "确认删除这个实例？此操作会删除该模拟器的数据文件。", .en: "Delete this instance? This will remove the emulator data files."],
        "boot": [.zh: "启动", .en: "Boot"],
        "stop": [.zh: "停止", .en: "Stop"],
        "device": [.zh: "设备", .en: "Device"],
        "androidVersion": [.zh: "安卓版本", .en: "Android Version"],
        "systemImage": [.zh: "系统镜像", .en: "System Image"],
        "android15": [.zh: "Android 15", .en: "Android 15"],
        "android9Compat": [.zh: "Android 9 兼容", .en: "Android 9 Compat"],
        "switchImage": [.zh: "切换系统版本", .en: "Switch Android"],
        "display": [.zh: "显示", .en: "Display"],
        "system": [.zh: "系统", .en: "System"],
        "macro": [.zh: "点击器", .en: "Clicker"],
        "performance": [.zh: "性能", .en: "Performance"],
        "data": [.zh: "数据", .en: "Data"],
        "developer": [.zh: "开发者", .en: "Developer"],
        "global": [.zh: "全局", .en: "Global"],
        "deviceName": [.zh: "设备名称", .en: "Device Name"],
        "phoneModel": [.zh: "手机型号", .en: "Phone Model"],
        "presetModel": [.zh: "预设型号", .en: "Preset Model"],
        "randomModel": [.zh: "随机型号", .en: "Random Model"],
        "brand": [.zh: "手机品牌", .en: "Brand"],
        "model": [.zh: "手机型号", .en: "Model"],
        "modelCode": [.zh: "入网型号", .en: "Model Code"],
        "imei": [.zh: "IMEI 编码", .en: "IMEI"],
        "phone": [.zh: "手机号码", .en: "Phone"],
        "gpu": [.zh: "GPU 型号", .en: "GPU"],
        "screenSize": [.zh: "屏幕尺寸", .en: "Screen Size"],
        "custom": [.zh: "自定义", .en: "Custom"],
        "frameRate": [.zh: "帧率显示", .en: "Frame Rate"],
        "autoRotate": [.zh: "窗口自动旋转", .en: "Auto Rotate"],
        "highQuality": [.zh: "高画质适配", .en: "High Quality"],
        "fps": [.zh: "帧数", .en: "FPS"],
        "profile": [.zh: "性能档位", .en: "Profile"],
        "memory": [.zh: "内存", .en: "Memory"],
        "cores": [.zh: "核心", .en: "Cores"],
        "disk": [.zh: "磁盘容量", .en: "Disk Size"],
        "checkStorage": [.zh: "检查真实空间", .en: "Check Storage"],
        "rebuildDataDisk": [.zh: "重建数据盘", .en: "Rebuild Data Disk"],
        "storage": [.zh: "实例目录", .en: "Instance Storage"],
        "root": [.zh: "Root", .en: "Root"],
        "adbEnabled": [.zh: "ADB", .en: "ADB"],
        "systemLanguage": [.zh: "系统语言", .en: "System Language"],
        "simplifiedChinese": [.zh: "简体中文", .en: "Simplified Chinese"],
        "englishUS": [.zh: "英文", .en: "English"],
        "accessibility": [.zh: "无障碍功能", .en: "Accessibility"],
        "accessibilityService": [.zh: "无障碍服务", .en: "Accessibility Service"],
        "batteryOptimization": [.zh: "关闭电源优化", .en: "Disable Battery Optimization"],
        "stayAwake": [.zh: "充电时保持唤醒", .en: "Stay Awake While Charging"],
        "androidSettings": [.zh: "安卓设置", .en: "Android Settings"],
        "applySystem": [.zh: "应用到系统", .en: "Apply to System"],
        "openAndroidSettings": [.zh: "打开安卓设置", .en: "Open Android Settings"],
        "openLanguageSettings": [.zh: "打开语言设置", .en: "Open Language Settings"],
        "openAccessibility": [.zh: "打开无障碍", .en: "Open Accessibility"],
        "openBattery": [.zh: "打开电源优化", .en: "Open Battery"],
        "repairNetwork": [.zh: "修复网络", .en: "Repair Network"],
        "autoOrientation": [.zh: "应用自动横屏", .en: "Auto App Rotation"],
        "landscapePackages": [.zh: "横屏应用包名", .en: "Landscape Packages"],
        "applyOrientation": [.zh: "应用方向", .en: "Apply Rotation"],
        "startMonitor": [.zh: "开始监听", .en: "Start Monitor"],
        "stopMonitor": [.zh: "停止监听", .en: "Stop Monitor"],
        "macroName": [.zh: "脚本名称", .en: "Script Name"],
        "script": [.zh: "脚本", .en: "Script"],
        "refreshScreen": [.zh: "刷新截图", .en: "Refresh Screen"],
        "recordTap": [.zh: "录制点击", .en: "Record Tap"],
        "recordSwipe": [.zh: "录制轨迹", .en: "Record Swipe"],
        "addWait": [.zh: "添加等待", .en: "Add Wait"],
        "saveScript": [.zh: "保存脚本", .en: "Save Script"],
        "playScript": [.zh: "播放脚本", .en: "Play Script"],
        "repeatCount": [.zh: "循环次数", .en: "Repeats"],
        "speed": [.zh: "速度", .en: "Speed"],
        "steps": [.zh: "步骤", .en: "Steps"],
        "headless": [.zh: "后台启动", .en: "Headless"],
        "snapshot": [.zh: "冷启动", .en: "Cold Boot"],
        "language": [.zh: "语言", .en: "Language"],
        "doctor": [.zh: "环境检查", .en: "Doctor"],
        "apk": [.zh: "APK 路径", .en: "APK Path"],
        "chooseAPK": [.zh: "选择 APK", .en: "Choose APK"],
        "install": [.zh: "安装 APK", .en: "Install APK"],
        "ready": [.zh: "就绪", .en: "Ready"]
    ]
}

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HStack(spacing: 0) {
                sidebar
                    .frame(width: 300)
                Divider()
                mainPanel
            }
            Divider()
            statusBar
        }
        .onAppear {
            viewModel.refresh()
        }
        .onChange(of: viewModel.selectedAVDName) {
            viewModel.loadSelectedInstance()
        }
        .confirmationDialog(
            t("deleteInstance"),
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button(t("delete"), role: .destructive) {
                viewModel.deleteSelectedInstance()
            }
        } message: {
            Text("\(t("deleteConfirm")) \(viewModel.selectedAVDName ?? "")")
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Text(t("title"))
                .font(.system(size: 18, weight: .semibold))

            Spacer()

            Picker(t("language"), selection: $viewModel.language) {
                Text("简体中文").tag(AppLanguage.zh)
                Text("English").tag(AppLanguage.en)
            }
            .pickerStyle(.segmented)
            .frame(width: 190)

            Button {
                viewModel.saveSelectedInstance()
            } label: {
                Label(t("save"), systemImage: "square.and.arrow.down")
            }
            .disabled(viewModel.selectedAVDName == nil)

            Button {
                viewModel.refresh()
            } label: {
                Label(t("refresh"), systemImage: "arrow.clockwise")
            }

            Button {
                viewModel.createInstance()
            } label: {
                Label(t("create"), systemImage: "plus")
            }

            Button {
                viewModel.copyInstance()
            } label: {
                Label(t("copy"), systemImage: "doc.on.doc")
            }
            .disabled(viewModel.selectedAVDName == nil)

            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                Label(t("delete"), systemImage: "trash")
            }
            .disabled(viewModel.selectedAVDName == nil)

            Button {
                viewModel.bootSelectedAVD()
            } label: {
                Label(t("boot"), systemImage: "play.fill")
            }
            .disabled(viewModel.selectedAVDName == nil)

            Button {
                viewModel.openAndroidSettings()
            } label: {
                Label(t("androidSettings"), systemImage: "gearshape")
            }
            .disabled(viewModel.activeDeviceSerial == nil)

            Button {
                viewModel.openAccessibilitySettings()
            } label: {
                Label(t("accessibility"), systemImage: "accessibility")
            }
            .disabled(viewModel.activeDeviceSerial == nil)
        }
        .padding(14)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("instances"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 14)

            List(selection: $viewModel.selectedAVDName) {
                ForEach(viewModel.avds) { avd in
                    Label(avd.name, systemImage: "iphone")
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.selectedAVDName = avd.name
                                isConfirmingDelete = true
                            } label: {
                                Label(t("delete"), systemImage: "trash")
                            }
                        }
                        .tag(avd.name as String?)
                }
            }

            Divider()

            Text(t("adb"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)

            List(selection: $viewModel.selectedSerial) {
                ForEach(viewModel.devices) { device in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.serial)
                            .font(.system(size: 13, weight: .medium))
                        Text(device.state.rawValue)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .tag(device.serial as String?)
                }
            }
        }
    }

    private var mainPanel: some View {
        VStack(spacing: 0) {
            Picker("", selection: $viewModel.selectedTab) {
                ForEach(SettingsTab.allCases, id: \.rawValue) { tab in
                    Label(tabTitle(tab), systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(18)

            Divider()

            ScrollView {
                Group {
                    switch viewModel.selectedTab {
                    case .device:
                        devicePanel
                    case .display:
                        displayPanel
                    case .system:
                        systemPanel
                    case .macro:
                        macroPanel
                    case .performance:
                        performancePanel
                    case .data:
                        dataPanel
                    case .developer:
                        developerPanel
                    case .global:
                        globalPanel
                    }
                }
                .padding(24)
                .frame(maxWidth: 760, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var devicePanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            formRow(t("androidVersion")) {
                Text(viewModel.androidVersion)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            formRow(t("deviceName")) {
                TextField(t("deviceName"), text: $viewModel.instanceName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 420)
            }

            formRow(t("phoneModel")) {
                Picker("", selection: $viewModel.randomModel) {
                    Text(t("presetModel")).tag(false)
                    Text(t("randomModel")).tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
            }

            VStack(alignment: .leading, spacing: 12) {
                formRow(t("brand")) {
                    Picker("", selection: $viewModel.selectedBrand) {
                        ForEach(DeviceCatalog.brands, id: \.self) { brand in
                            Text(brand).tag(brand)
                        }
                    }
                    .frame(width: 260)
                    .onChange(of: viewModel.selectedBrand) {
                        viewModel.updateModelForBrand()
                    }
                }

                formRow(t("model")) {
                    Picker("", selection: $viewModel.selectedModelName) {
                        ForEach(DeviceCatalog.models(for: viewModel.selectedBrand), id: \.modelName) { spec in
                            Text(spec.modelName).tag(spec.modelName)
                        }
                    }
                    .frame(width: 260)
                    .disabled(viewModel.randomModel)
                }

                formRow(t("modelCode")) {
                    Text(viewModel.selectedSpec.modelCode)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

            formRow(t("imei")) {
                TextField(t("imei"), text: $viewModel.imei)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                Button {
                    viewModel.randomizeIdentity()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }

            formRow(t("phone")) {
                TextField(t("phone"), text: $viewModel.phoneNumber)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
            }

            formRow(t("gpu")) {
                Picker("", selection: $viewModel.gpuTier) {
                    Text("高配").tag("high")
                    Text("均衡").tag("balanced")
                }
                .frame(width: 120)
                Text(viewModel.gpuName)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var displayPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            formRow(t("screenSize")) {
                Picker("", selection: $viewModel.screenCategory) {
                    Text("平板").tag(ScreenCategory.tablet)
                    Text("手机").tag(ScreenCategory.phone)
                    Text(t("custom")).tag(ScreenCategory.custom)
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(DisplayProfile.presets.filter { $0.category == viewModel.screenCategory || viewModel.screenCategory == .custom }) { preset in
                    Button {
                        viewModel.applyDisplay(preset)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.displayID == preset.id ? "largecircle.fill.circle" : "circle")
                            Text(presetLabel(preset))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 360, alignment: .leading)
            .padding(14)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

            formRow(t("fps")) {
                Stepper("\(viewModel.fps)", value: $viewModel.fps, in: 15...120, step: 5)
                    .frame(width: 110)
            }
            Toggle(t("frameRate"), isOn: $viewModel.frameRateVisible)
            Toggle(t("autoRotate"), isOn: $viewModel.autoRotate)
            Toggle(t("highQuality"), isOn: $viewModel.highQuality)
        }
    }

    private var performancePanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            formRow(t("profile")) {
                Picker("", selection: $viewModel.profileRawValue) {
                    ForEach(RuntimeProfile.allCases, id: \.rawValue) { profile in
                        Text(profile.displayName).tag(profile.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 420)
                .onChange(of: viewModel.profileRawValue) {
                    viewModel.applyRuntimeProfile()
                }
            }

            formRow(t("memory")) {
                Stepper("\(viewModel.memoryMB) MB", value: $viewModel.memoryMB, in: 1536...12288, step: 512)
                    .frame(width: 150)
            }

            formRow(t("cores")) {
                Stepper("\(viewModel.cores)", value: $viewModel.cores, in: 1...8)
                    .frame(width: 90)
            }

            formRow(t("gpu")) {
                Picker("", selection: $viewModel.gpuMode) {
                    Text("Auto").tag("auto")
                    Text("Host").tag("host")
                    Text("SwiftShader").tag("swiftshader_indirect")
                }
                .pickerStyle(.segmented)
                .frame(width: 360)
            }
        }
    }

    private var dataPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            formRow(t("disk")) {
                Stepper(
                    "\(viewModel.diskSizeGB) GB",
                    value: Binding(
                        get: { viewModel.diskSizeGB },
                        set: { viewModel.diskSizeGB = $0 }
                    ),
                    in: 8...256,
                    step: 1
                )
                .frame(width: 150)
                Button {
                    viewModel.checkStorage()
                } label: {
                    Label(t("checkStorage"), systemImage: "internaldrive")
                }
                .disabled(viewModel.activeDeviceSerial == nil)
                Button {
                    viewModel.rebuildDataDisk()
                } label: {
                    Label(t("rebuildDataDisk"), systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(viewModel.selectedAVDName == nil)
            }

            if !viewModel.dataStorageMessage.isEmpty {
                Text(viewModel.dataStorageMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            formRow(t("storage")) {
                Text(StorageLayout.preferredAVDHome().path)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            formRow(t("apk")) {
                TextField(t("apk"), text: $viewModel.apkPath)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 420)
                Button {
                    viewModel.chooseAPK()
                } label: {
                    Label(t("chooseAPK"), systemImage: "folder")
                }
                Button {
                    viewModel.installAPK()
                } label: {
                    Label(t("install"), systemImage: "square.and.arrow.down")
                }
                .disabled(viewModel.apkPath.isEmpty)
            }
        }
    }

    private var systemPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            formRow(t("systemLanguage")) {
                Picker("", selection: $viewModel.guestLocale) {
                    Text(t("simplifiedChinese")).tag("zh-CN")
                    Text(t("englishUS")).tag("en-US")
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
            }

            Toggle(t("accessibility"), isOn: $viewModel.accessibilityEnabled)

            formRow(t("accessibilityService")) {
                TextField("package/.Service", text: $viewModel.accessibilityService)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 380)
            }

            Toggle(t("batteryOptimization"), isOn: $viewModel.batteryOptimizationDisabled)
            Toggle(t("stayAwake"), isOn: $viewModel.stayAwakeWhileCharging)
            Toggle(t("autoOrientation"), isOn: $viewModel.autoOrientationEnabled)

            formRow(t("landscapePackages")) {
                TextField("com.u1game.cabalm", text: $viewModel.landscapePackagesText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 420)
            }

            HStack {
                Button {
                    viewModel.saveSelectedInstance()
                } label: {
                    Label(t("save"), systemImage: "square.and.arrow.down")
                }
                .disabled(viewModel.selectedAVDName == nil)

                Button {
                    viewModel.applySystemSettings()
                } label: {
                    Label(t("applySystem"), systemImage: "checkmark.circle")
                }
                .disabled(viewModel.selectedAVDName == nil)

                Button {
                    viewModel.openAndroidSettings()
                } label: {
                    Label(t("openAndroidSettings"), systemImage: "gearshape")
                }
                .disabled(viewModel.activeDeviceSerial == nil)

                Button {
                    viewModel.openLanguageSettings()
                } label: {
                    Label(t("openLanguageSettings"), systemImage: "globe")
                }
                .disabled(viewModel.activeDeviceSerial == nil)

                Button {
                    viewModel.openAccessibilitySettings()
                } label: {
                    Label(t("openAccessibility"), systemImage: "accessibility")
                }
                .disabled(viewModel.activeDeviceSerial == nil)
            }

            HStack {
                Button {
                    viewModel.applyOrientationForCurrentApp()
                } label: {
                    Label(t("applyOrientation"), systemImage: "rectangle.rotate.90")
                }
                .disabled(viewModel.activeDeviceSerial == nil)

                Button {
                    viewModel.toggleOrientationMonitor()
                } label: {
                    Label(
                        viewModel.orientationMonitorActive ? t("stopMonitor") : t("startMonitor"),
                        systemImage: viewModel.orientationMonitorActive ? "stop.circle" : "play.circle"
                    )
                }
                .disabled(viewModel.activeDeviceSerial == nil)

                Button {
                    viewModel.openBatterySettings()
                } label: {
                    Label(t("openBattery"), systemImage: "battery.100")
                }
                .disabled(viewModel.activeDeviceSerial == nil)

                Button {
                    viewModel.repairNetwork()
                } label: {
                    Label(t("repairNetwork"), systemImage: "network")
                }
                .disabled(viewModel.activeDeviceSerial == nil)
            }
        }
    }

    private var macroPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            formRow(t("macroName")) {
                TextField(t("macroName"), text: $viewModel.macroName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)
                Button {
                    viewModel.refreshMacroScreenshot()
                } label: {
                    Label(t("refreshScreen"), systemImage: "camera.viewfinder")
                }
                .disabled(viewModel.activeDeviceSerial == nil)
            }

            formRow(t("script")) {
                Picker("", selection: $viewModel.selectedMacroID) {
                    Text("New").tag(UUID?.none)
                    ForEach(viewModel.macroScripts) { script in
                        Text(script.name).tag(Optional(script.id))
                    }
                }
                .frame(width: 280)
                .onChange(of: viewModel.selectedMacroID) {
                    viewModel.loadSelectedMacro()
                }
            }

            HStack(alignment: .top, spacing: 18) {
                macroRecorderSurface

                VStack(alignment: .leading, spacing: 12) {
                    Picker("", selection: $viewModel.macroRecordMode) {
                        Text(t("recordTap")).tag(MacroRecordMode.tap)
                        Text(t("recordSwipe")).tag(MacroRecordMode.swipe)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)

                    HStack {
                        Button {
                            viewModel.addMacroWait()
                        } label: {
                            Label(t("addWait"), systemImage: "timer")
                        }
                        Button {
                            viewModel.saveMacroScript()
                        } label: {
                            Label(t("saveScript"), systemImage: "square.and.arrow.down")
                        }
                    }

                    formRow(t("repeatCount")) {
                        Stepper("\(viewModel.macroRepeatCount)", value: $viewModel.macroRepeatCount, in: 1...999)
                            .frame(width: 110)
                    }

                    formRow(t("speed")) {
                        Stepper(String(format: "%.1fx", viewModel.macroSpeed), value: $viewModel.macroSpeed, in: 0.2...5.0, step: 0.1)
                            .frame(width: 120)
                    }

                    Button {
                        viewModel.playMacroScript()
                    } label: {
                        Label(t("playScript"), systemImage: "play.fill")
                    }
                    .disabled(viewModel.activeDeviceSerial == nil || viewModel.currentMacroSteps.isEmpty)

                    Text("\(t("steps")): \(viewModel.currentMacroSteps.count)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(viewModel.currentMacroSteps.enumerated()), id: \.element.id) { index, step in
                                Text("\(index + 1). \(viewModel.stepSummary(step))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(width: 300, height: 210, alignment: .topLeading)
                }
            }
        }
    }

    private var macroRecorderSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.black.opacity(0.18))
            if let image = viewModel.macroScreenshot {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                Text(t("refreshScreen"))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 360, height: 230)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    viewModel.recordMacroGesture(
                        start: value.startLocation,
                        end: value.location,
                        viewSize: CGSize(width: 360, height: 230)
                    )
                }
        )
    }

    private var developerPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle(t("root"), isOn: $viewModel.rootEnabled)
            Toggle(t("adbEnabled"), isOn: $viewModel.adbEnabled)
            Toggle(t("headless"), isOn: $viewModel.headless)
            Toggle(t("snapshot"), isOn: $viewModel.noSnapshot)

            formRow(t("systemImage")) {
                TextField(t("systemImage"), text: $viewModel.systemImagePackage)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 430)
                Button(t("android15")) {
                    viewModel.systemImagePackage = DeviceProfile.appleSiliconDefaultImage
                }
                Button(t("android9Compat")) {
                    viewModel.systemImagePackage = DeviceProfile.appleSiliconGameCompatibilityImage
                }
                Button(t("switchImage")) {
                    viewModel.switchSystemImage()
                }
                .disabled(viewModel.selectedAVDName == nil)
            }

            HStack {
                Button {
                    viewModel.applySystemSettings()
                } label: {
                    Label(t("applySystem"), systemImage: "checkmark.circle")
                }
                .disabled(viewModel.activeDeviceSerial == nil || viewModel.selectedAVDName == nil)

                Button {
                    viewModel.openAccessibilitySettings()
                } label: {
                    Label(t("openAccessibility"), systemImage: "accessibility")
                }
                .disabled(viewModel.activeDeviceSerial == nil)

                Button {
                    viewModel.openBatterySettings()
                } label: {
                    Label(t("openBattery"), systemImage: "battery.100")
                }
                .disabled(viewModel.activeDeviceSerial == nil)
            }

            HStack {
                Button {
                    viewModel.rootSelectedDevice()
                } label: {
                    Label(t("root"), systemImage: "number")
                }
                .disabled(viewModel.selectedSerial == nil)

                Button {
                    viewModel.stopSelectedDevice()
                } label: {
                    Label(t("stop"), systemImage: "stop.fill")
                }
                .disabled(viewModel.selectedSerial == nil)
            }
        }
    }

    private var globalPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(t("doctor"))
                .font(.system(size: 16, weight: .semibold))

            ForEach(viewModel.diagnostics) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: icon(for: item.status))
                        .foregroundStyle(color(for: item.status))
                        .frame(width: 18)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.system(size: 13, weight: .medium))
                        Text(item.path ?? item.message)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    private var statusBar: some View {
        HStack {
            Circle()
                .fill(viewModel.statusColor)
                .frame(width: 8, height: 8)
            Text(viewModel.statusMessage)
                .lineLimit(1)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func formRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 120, alignment: .trailing)
            content()
        }
    }

    private func presetLabel(_ preset: DisplayProfile) -> String {
        "\(preset.width) x \(preset.height)  \(preset.dpi) DPI"
    }

    private func tabTitle(_ tab: SettingsTab) -> String {
        t(tab.rawValue)
    }

    private func t(_ key: String) -> String {
        L10n.text(key, viewModel.language)
    }

    private func icon(for status: DiagnosticStatus) -> String {
        switch status {
        case .ok:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }

    private func color(for status: DiagnosticStatus) -> Color {
        switch status {
        case .ok:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {
    private static let initialIdentity = VirtualIdentityGenerator.makeIdentity()

    @Published var language: AppLanguage = .zh
    @Published var selectedTab: SettingsTab = .device
    @Published var diagnostics: [SDKDiagnostic] = []
    @Published var avds: [AVD] = []
    @Published var devices: [AndroidDevice] = []
    @Published var selectedAVDName: String?
    @Published var selectedSerial: String?
    @Published var statusMessage = L10n.text("ready", .zh)
    @Published var statusColor = Color.secondary
    @Published var androidVersion = "Android 15 / API 35"
    @Published var systemImagePackage = DeviceProfile.appleSiliconDefaultImage

    @Published var instanceName = "macos_phone_01"
    @Published var randomModel = false
    @Published var selectedBrand = DeviceCatalog.defaultSpec.brand
    @Published var selectedModelName = DeviceCatalog.defaultSpec.modelName
    @Published var imei = DashboardViewModel.initialIdentity.imei
    @Published var phoneNumber = DashboardViewModel.initialIdentity.phoneNumber
    @Published var gpuTier = "high"

    @Published var screenCategory = DisplayProfile.defaultPreset.category
    @Published var displayID = DisplayProfile.defaultPreset.id
    @Published var width = DisplayProfile.defaultPreset.width
    @Published var height = DisplayProfile.defaultPreset.height
    @Published var dpi = DisplayProfile.defaultPreset.dpi
    @Published var fps = DisplayProfile.defaultPreset.fps
    @Published var frameRateVisible = false
    @Published var autoRotate = true
    @Published var highQuality = false

    @Published var profileRawValue = RuntimeProfile.lean.rawValue
    @Published var gpuMode = RuntimeProfile.lean.gpuMode
    @Published var memoryMB = RuntimeProfile.lean.memoryMB
    @Published var cores = RuntimeProfile.lean.cores
    @Published var diskSizeMB = RuntimeProfile.lean.diskSizeMB
    @Published var rootEnabled = false
    @Published var adbEnabled = true
    @Published var guestLocale = GuestSystemSettings.default.localeIdentifier
    @Published var accessibilityEnabled = GuestSystemSettings.default.accessibilityEnabled
    @Published var accessibilityService = GuestSystemSettings.default.accessibilityService
    @Published var batteryOptimizationDisabled = GuestSystemSettings.default.batteryOptimizationDisabled
    @Published var stayAwakeWhileCharging = GuestSystemSettings.default.stayAwakeWhileCharging
    @Published var headless = false
    @Published var noSnapshot = false
    @Published var apkPath = ""
    @Published var dataStorageMessage = ""
    @Published var autoOrientationEnabled = true
    @Published var landscapePackagesText = "com.u1game.cabalm"
    @Published var orientationMonitorActive = true
    @Published var macroName = "game_macro"
    @Published var macroScripts: [MacroScript] = []
    @Published var selectedMacroID: UUID?
    @Published var currentMacroSteps: [MacroStep] = []
    @Published var macroRecordMode = MacroRecordMode.tap
    @Published var macroRepeatCount = 1
    @Published var macroSpeed = 1.0
    @Published var macroScreenshot: NSImage?
    @Published var macroScreenshotSize = CGSize(width: 720, height: 1280)

    private var currentIdentity = DashboardViewModel.initialIdentity
    private var isApplyingSelection = false
    private var orientationTimer: Timer?

    var selectedSpec: AndroidDeviceSpec {
        DeviceCatalog.resolve(brand: selectedBrand, modelName: selectedModelName) ?? DeviceCatalog.defaultSpec
    }

    var gpuName: String {
        gpuTier == "high" ? selectedSpec.gpuHigh : selectedSpec.gpuBalanced
    }

    var activeDeviceSerial: String? {
        selectedSerial ?? devices.first(where: { $0.state == .device })?.serial ?? devices.first?.serial
    }

    var diskSizeGB: Int {
        get {
            max(1, diskSizeMB / 1024)
        }
        set {
            diskSizeMB = max(1, newValue) * 1024
        }
    }

    func refresh() {
        let sdk = AndroidSDKLocator.discover()
        diagnostics = AndroidSDKLocator.diagnostics(for: sdk)
        macroScripts = (try? MacroScriptStore.list()) ?? []

        guard let sdk else {
            avds = []
            devices = []
            report("Android SDK missing", color: .red)
            return
        }

        let platform = MOSPlatform(sdk: sdk)
        do {
            avds = try platform.avdManager.listAVDs()
            devices = try platform.adbManager.devices()
            if let selectedAVDName, !avds.contains(where: { $0.name == selectedAVDName }) {
                self.selectedAVDName = avds.first?.name
            } else {
                selectedAVDName = selectedAVDName ?? avds.first?.name
            }
            selectedSerial = selectedSerial ?? devices.first?.serial
            if let serial = activeDeviceSerial,
               let version = try? platform.adbManager.androidVersion(serial: serial) {
                androidVersion = version
            } else {
                androidVersion = "Android 15 / API 35"
            }
            loadSelectedInstance(platform: platform)
            ensureOrientationMonitor()
            report(L10n.text("ready", language), color: .secondary)
        } catch {
            report(String(describing: error), color: .orange)
        }
    }

    func createInstance() {
        let requestedName = normalizedInstanceName(instanceName)
        let name = nextAvailableInstanceName(base: requestedName)
        let configuration = makeConfiguration(name: name, preserveIdentity: false, reuseTypedIdentity: false)
        perform("Creating \(name)") { platform in
            try platform.avdManager.createAVD(
                configuration: configuration,
                package: configuration.resolvedSystemImagePackage,
                device: DeviceProfile.appleSiliconDefault.deviceIdentifier,
                force: false
            )
        }
        instanceName = name
    }

    func copyInstance() {
        guard let selectedAVDName else {
            return
        }

        let requestedDestination = normalizedInstanceName(instanceName.isEmpty ? "\(selectedAVDName)_copy" : instanceName)
        let destination = nextAvailableInstanceName(base: requestedDestination == selectedAVDName ? "\(selectedAVDName)_copy" : requestedDestination)
        perform("Copying \(destination)") { platform in
            _ = try platform.avdManager.copyAVD(
                sourceName: selectedAVDName,
                destinationName: destination,
                randomizedSpec: DeviceCatalog.randomSpec(),
                display: currentDisplay,
                runtimeProfile: selectedRuntimeProfile,
                diskSizeMB: diskSizeMB,
                rootEnabled: rootEnabled,
                adbEnabled: adbEnabled,
                force: false
            )
        }
        instanceName = destination
    }

    func switchSystemImage() {
        guard let selectedAVDName else {
            return
        }
        let package = systemImagePackage
        perform("Switching Android image") { platform in
            _ = try platform.avdManager.switchSystemImage(
                name: selectedAVDName,
                package: package,
                device: DeviceProfile.appleSiliconDefault.deviceIdentifier
            )
        }
    }

    func deleteSelectedInstance() {
        guard let selectedAVDName else {
            return
        }

        perform("Deleting \(selectedAVDName)") { platform in
            try platform.avdManager.deleteAVD(name: selectedAVDName)
        }
    }

    func saveSelectedInstance() {
        guard let selectedAVDName else {
            return
        }

        let configuration = makeConfiguration(name: selectedAVDName, preserveIdentity: true, reuseTypedIdentity: true)
        perform("Saving \(selectedAVDName)") { platform in
            try platform.avdManager.applyConfiguration(configuration)
        }
    }

    func loadSelectedInstance() {
        guard !isApplyingSelection else {
            return
        }
        do {
            let platform = try MOSPlatform.discover()
            loadSelectedInstance(platform: platform)
        } catch {
            report(String(describing: error), color: .orange)
        }
    }

    func bootSelectedAVD() {
        guard let selectedAVDName else {
            return
        }

        perform("Booting \(selectedAVDName)") { platform in
            let options: LaunchOptions
            if let configuration = platform.avdManager.configuration(for: selectedAVDName) {
                options = LaunchOptions(
                    configuration: configuration,
                    headless: headless,
                    noSnapshotLoad: noSnapshot
                )
            } else {
                options = LaunchOptions(
                    profile: selectedRuntimeProfile,
                    headless: headless,
                    memoryMB: memoryMB,
                    cores: cores,
                    gpuMode: gpuMode,
                    noSnapshotLoad: noSnapshot
                )
            }
            _ = try platform.emulatorManager.launch(avdName: selectedAVDName, options: options)
        }
        ensureOrientationMonitor()
    }

    func installAPK() {
        let serial = activeDeviceSerial
        guard let serial else {
            report("No running device", color: .orange)
            return
        }

        perform("Installing APK") { platform in
            let availableBytes = try platform.adbManager.availableDataBytes(serial: serial)
            let apkBytes = (try? FileManager.default.attributesOfItem(atPath: apkPath)[.size] as? NSNumber)?.int64Value ?? 0
            if apkBytes > 0, availableBytes < apkBytes + 2 * 1024 * 1024 * 1024 {
                throw MOSError.invalidArgument("Android /data free space is too small. Free: \(Self.formatBytes(availableBytes)), APK: \(Self.formatBytes(apkBytes)). Increase disk size and rebuild the data disk.")
            }
            try platform.adbManager.installAPK(serial: serial, apkPath: apkPath)
        }
    }

    func chooseAPK() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "apk") ?? .data]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            apkPath = url.path
        }
    }

    func checkStorage() {
        guard let serial = activeDeviceSerial else {
            report("No running device", color: .orange)
            return
        }

        perform("Checking storage") { platform in
            let availableBytes = try platform.adbManager.availableDataBytes(serial: serial)
            dataStorageMessage = "Android /data available: \(Self.formatBytes(availableBytes))"
        }
    }

    func rebuildDataDisk() {
        guard let selectedAVDName else {
            return
        }

        perform("Rebuilding data disk") { platform in
            let backup = try platform.avdManager.rebuildDataDisk(named: selectedAVDName)
            dataStorageMessage = "Old data disk backed up: \(backup.path). Stop the emulator before using this, then boot again."
        }
    }

    func stopSelectedDevice() {
        guard let selectedSerial else {
            return
        }

        perform("Stopping \(selectedSerial)") { platform in
            try platform.adbManager.killEmulator(serial: selectedSerial)
        }
    }

    func rootSelectedDevice() {
        guard let selectedSerial else {
            return
        }

        perform("Root \(selectedSerial)") { platform in
            try platform.adbManager.root(serial: selectedSerial)
        }
    }

    func applySystemSettings() {
        guard let selectedAVDName else {
            return
        }
        let serial = activeDeviceSerial
        guard let serial else {
            report("No running device", color: .orange)
            return
        }

        let configuration = makeConfiguration(name: selectedAVDName, preserveIdentity: true)
        perform("Applying system settings") { platform in
            try platform.avdManager.applyConfiguration(configuration)
            try platform.adbManager.applyVirtualIdentity(serial: serial, configuration: configuration)
            try platform.adbManager.applyGuestSystemSettings(serial: serial, configuration: configuration)
        }
    }

    func openAndroidSettings() {
        guard let serial = activeDeviceSerial else {
            report("No running device", color: .orange)
            return
        }
        perform("Opening Android Settings") { platform in
            try platform.adbManager.openAndroidSettings(serial: serial)
        }
    }

    func openLanguageSettings() {
        guard let serial = activeDeviceSerial else {
            report("No running device", color: .orange)
            return
        }
        perform("Opening Language Settings") { platform in
            try platform.adbManager.openLanguageSettings(serial: serial)
        }
    }

    func openAccessibilitySettings() {
        guard let serial = activeDeviceSerial else {
            report("No running device", color: .orange)
            return
        }
        perform("Opening Accessibility") { platform in
            try platform.adbManager.openAccessibilitySettings(serial: serial)
        }
    }

    func openBatterySettings() {
        guard let serial = activeDeviceSerial else {
            report("No running device", color: .orange)
            return
        }
        perform("Opening Battery") { platform in
            try platform.adbManager.openBatteryOptimizationSettings(serial: serial)
        }
    }

    func repairNetwork() {
        guard let serial = activeDeviceSerial else {
            report("No running device", color: .orange)
            return
        }
        perform("Repairing network") { platform in
            try platform.adbManager.stabilizeNetwork(serial: serial)
        }
    }

    func applyOrientationForCurrentApp(silent: Bool = false) {
        guard let serial = activeDeviceSerial else {
            if !silent {
                report("No running device", color: .orange)
            }
            return
        }

        if !silent {
            report("Applying orientation", color: .orange)
        }
        do {
            let platform = try MOSPlatform.discover()
            let packageName = try platform.adbManager.foregroundPackage(serial: serial) ?? ""
            try applyOrientation(packageName: packageName, serial: serial, platform: platform)
        } catch {
            if !silent {
                report(String(describing: error), color: .red)
            }
        }
    }

    func toggleOrientationMonitor() {
        if orientationMonitorActive {
            orientationTimer?.invalidate()
            orientationTimer = nil
            orientationMonitorActive = false
            report("Orientation monitor stopped", color: .secondary)
            return
        }

        guard activeDeviceSerial != nil else {
            report("No running device", color: .orange)
            return
        }

        orientationMonitorActive = true
        ensureOrientationMonitor()
        applyOrientationForCurrentApp()
    }

    func refreshMacroScreenshot() {
        guard let serial = activeDeviceSerial else {
            report("No running device", color: .orange)
            return
        }

        perform("Capturing screen") { platform in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("macos-macro-\(UUID().uuidString).png")
            try platform.adbManager.captureScreenshot(serial: serial, to: url)
            guard let image = NSImage(contentsOf: url) else {
                throw MOSError.invalidArgument("Unable to load captured screenshot.")
            }
            macroScreenshot = image
            macroScreenshotSize = image.size
        }
    }

    func recordMacroGesture(start: CGPoint, end: CGPoint, viewSize: CGSize) {
        let startPoint = mapMacroPoint(start, viewSize: viewSize)
        let endPoint = mapMacroPoint(end, viewSize: viewSize)
        switch macroRecordMode {
        case .tap:
            currentMacroSteps.append(
                MacroStep(kind: .tap, x: startPoint.x, y: startPoint.y, delayAfterMS: 250)
            )
        case .swipe:
            currentMacroSteps.append(
                MacroStep(
                    kind: .swipe,
                    x: startPoint.x,
                    y: startPoint.y,
                    x2: endPoint.x,
                    y2: endPoint.y,
                    durationMS: 350,
                    delayAfterMS: 250
                )
            )
        }
    }

    func addMacroWait() {
        currentMacroSteps.append(MacroStep(kind: .wait, durationMS: 0, delayAfterMS: 1000))
    }

    func saveMacroScript() {
        do {
            let size = macroScreenshotSize
            let now = Date()
            let script = MacroScript(
                id: selectedMacroID ?? UUID(),
                name: macroName.isEmpty ? "game_macro" : macroName,
                targetPackage: landscapePackages.first ?? "",
                baseWidth: max(1, Int(size.width)),
                baseHeight: max(1, Int(size.height)),
                steps: currentMacroSteps,
                createdAt: now,
                updatedAt: now
            )
            _ = try MacroScriptStore.write(script)
            macroScripts = try MacroScriptStore.list()
            selectedMacroID = script.id
            report("Macro saved: \(script.name)", color: .green)
        } catch {
            report(String(describing: error), color: .red)
        }
    }

    func loadSelectedMacro() {
        guard let selectedMacroID,
              let script = macroScripts.first(where: { $0.id == selectedMacroID })
        else {
            return
        }
        macroName = script.name
        currentMacroSteps = script.steps
        macroScreenshotSize = CGSize(width: script.baseWidth, height: script.baseHeight)
    }

    func playMacroScript() {
        guard let serial = activeDeviceSerial else {
            report("No running device", color: .orange)
            return
        }

        let script = MacroScript(
            id: selectedMacroID ?? UUID(),
            name: macroName.isEmpty ? "game_macro" : macroName,
            targetPackage: landscapePackages.first ?? "",
            baseWidth: max(1, Int(macroScreenshotSize.width)),
            baseHeight: max(1, Int(macroScreenshotSize.height)),
            steps: currentMacroSteps
        )
        perform("Playing macro") { platform in
            try platform.adbManager.playMacro(
                serial: serial,
                script: script,
                repeatCount: macroRepeatCount,
                speed: macroSpeed
            )
        }
    }

    func stepSummary(_ step: MacroStep) -> String {
        switch step.kind {
        case .tap:
            return "tap \(step.x),\(step.y)"
        case .swipe:
            return "swipe \(step.x),\(step.y) -> \(step.x2 ?? step.x),\(step.y2 ?? step.y)"
        case .wait:
            return "wait \(step.delayAfterMS)ms"
        }
    }

    func randomizeIdentity() {
        let identity = VirtualIdentityGenerator.makeIdentity(for: randomModel ? DeviceCatalog.randomSpec() : selectedSpec)
        currentIdentity = identity
        imei = identity.imei
        phoneNumber = identity.phoneNumber
    }

    func updateModelForBrand() {
        selectedModelName = DeviceCatalog.models(for: selectedBrand).first?.modelName ?? DeviceCatalog.defaultSpec.modelName
    }

    func applyDisplay(_ profile: DisplayProfile) {
        displayID = profile.id
        screenCategory = profile.category
        width = profile.width
        height = profile.height
        dpi = profile.dpi
        fps = profile.fps
        frameRateVisible = profile.frameRateVisible
        autoRotate = profile.autoRotate
        highQuality = profile.highQuality
    }

    func applyRuntimeProfile() {
        let profile = selectedRuntimeProfile
        memoryMB = profile.memoryMB
        cores = profile.cores
        diskSizeMB = profile.diskSizeMB
        gpuMode = profile.gpuMode
    }

    private func makeConfiguration(
        name: String,
        preserveIdentity: Bool,
        reuseTypedIdentity: Bool = true
    ) -> InstanceConfiguration {
        let spec = randomModel ? DeviceCatalog.randomSpec() : selectedSpec
        var identity = preserveIdentity ? currentIdentity : VirtualIdentityGenerator.makeIdentity(for: spec)
        if reuseTypedIdentity, VirtualIdentityGenerator.isValidIMEI(imei) {
            identity = VirtualIdentity(
                imei: imei,
                imsi: identity.imsi,
                androidId: identity.androidId,
                serialNumber: identity.serialNumber,
                wifiMacAddress: identity.wifiMacAddress,
                phoneNumber: phoneNumber.isEmpty ? identity.phoneNumber : phoneNumber
            )
        }
        currentIdentity = identity

        return InstanceConfiguration(
            avdName: name,
            deviceName: name,
            deviceSpec: spec,
            identity: identity,
            display: currentDisplay,
            runtimeProfile: selectedRuntimeProfile,
            diskSizeMB: diskSizeMB,
            rootEnabled: rootEnabled,
            adbEnabled: adbEnabled,
            systemImagePackage: systemImagePackage,
            systemSettings: currentSystemSettings,
            orientationRules: currentOrientationRules
        )
    }

    private var currentSystemSettings: GuestSystemSettings {
        GuestSystemSettings(
            localeIdentifier: guestLocale,
            accessibilityEnabled: accessibilityEnabled,
            accessibilityService: accessibilityService,
            batteryOptimizationDisabled: batteryOptimizationDisabled,
            stayAwakeWhileCharging: stayAwakeWhileCharging
        )
    }

    private var currentDisplay: DisplayProfile {
        DisplayProfile(
            name: "\(width) x \(height) \(dpi) DPI",
            category: screenCategory,
            width: width,
            height: height,
            dpi: dpi,
            fps: fps,
            frameRateVisible: frameRateVisible,
            autoRotate: autoRotate,
            highQuality: highQuality
        )
    }

    private var selectedRuntimeProfile: RuntimeProfile {
        RuntimeProfile(rawValue: profileRawValue) ?? .lean
    }

    private var landscapePackages: [String] {
        landscapePackagesText
            .split { $0 == "\n" || $0 == "," || $0 == " " }
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private var currentOrientationRules: [AppOrientationRule] {
        guard autoOrientationEnabled else {
            return []
        }
        return landscapePackages.map { AppOrientationRule(packageName: $0, orientation: .landscape) }
    }

    private func apply(configuration: InstanceConfiguration) {
        isApplyingSelection = true
        defer { isApplyingSelection = false }
        instanceName = configuration.avdName
        selectedBrand = configuration.deviceSpec.brand
        selectedModelName = configuration.deviceSpec.modelName
        currentIdentity = configuration.identity
        imei = configuration.identity.imei
        phoneNumber = configuration.identity.phoneNumber
        applyDisplay(configuration.display)
        profileRawValue = configuration.runtimeProfile.rawValue
        memoryMB = configuration.runtimeProfile.memoryMB
        cores = configuration.runtimeProfile.cores
        gpuMode = configuration.runtimeProfile.gpuMode
        diskSizeMB = configuration.diskSizeMB
        rootEnabled = configuration.rootEnabled
        adbEnabled = configuration.adbEnabled
        systemImagePackage = configuration.resolvedSystemImagePackage
        let systemSettings = configuration.resolvedSystemSettings
        guestLocale = systemSettings.localeIdentifier
        accessibilityEnabled = systemSettings.accessibilityEnabled
        accessibilityService = systemSettings.accessibilityService
        batteryOptimizationDisabled = systemSettings.batteryOptimizationDisabled
        stayAwakeWhileCharging = systemSettings.stayAwakeWhileCharging
        let rules = configuration.resolvedOrientationRules
        autoOrientationEnabled = !rules.isEmpty
        let landscape = rules.filter { $0.orientation == .landscape }.map(\.packageName)
        if !landscape.isEmpty {
            landscapePackagesText = landscape.joined(separator: "\n")
        }
    }

    private func loadSelectedInstance(platform: MOSPlatform) {
        guard let selectedAVDName,
              let config = platform.avdManager.configuration(for: selectedAVDName)
        else {
            return
        }
        apply(configuration: config)
    }

    private func perform(_ message: String, action: (MOSPlatform) throws -> Void) {
        report(message, color: .orange)
        do {
            let platform = try MOSPlatform.discover()
            try action(platform)
            refresh()
        } catch {
            report(String(describing: error), color: .red)
        }
    }

    private func report(_ message: String, color: Color) {
        statusMessage = message
        statusColor = color
    }

    private func applyOrientation(packageName: String, serial: String, platform: MOSPlatform) throws {
        let isLandscape = autoOrientationEnabled && landscapePackages.contains(packageName)
        if isLandscape {
            try platform.adbManager.setDisplay(serial: serial, width: 1280, height: 720, dpi: 240, rotation: 1)
            report("Landscape: \(packageName)", color: .green)
        } else {
            try platform.adbManager.setDisplay(serial: serial, width: width, height: height, dpi: dpi, rotation: 0)
            report(packageName.isEmpty ? "Portrait" : "Portrait: \(packageName)", color: .green)
        }
    }

    private func ensureOrientationMonitor() {
        guard orientationMonitorActive, orientationTimer == nil else {
            return
        }

        orientationTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.applyOrientationForCurrentApp(silent: true)
            }
        }
    }

    private func mapMacroPoint(_ point: CGPoint, viewSize: CGSize) -> (x: Int, y: Int) {
        let imageSize = macroScreenshotSize
        let scale = min(viewSize.width / max(1, imageSize.width), viewSize.height / max(1, imageSize.height))
        let renderedWidth = imageSize.width * scale
        let renderedHeight = imageSize.height * scale
        let offsetX = (viewSize.width - renderedWidth) / 2
        let offsetY = (viewSize.height - renderedHeight) / 2
        let normalizedX = min(max((point.x - offsetX) / max(1, renderedWidth), 0), 1)
        let normalizedY = min(max((point.y - offsetY) / max(1, renderedHeight), 0), 1)
        return (
            x: Int(normalizedX * imageSize.width),
            y: Int(normalizedY * imageSize.height)
        )
    }

    private static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func normalizedInstanceName(_ value: String) -> String {
        let raw = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            return "macos_phone_01"
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let chars = raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        return String(chars)
    }

    private func nextAvailableInstanceName(base: String) -> String {
        let existing = Set(avds.map(\.name))
        if !existing.contains(base) {
            return base
        }

        for index in 1...999 {
            let candidate = "\(base)_copy_\(String(format: "%02d", index))"
            if !existing.contains(candidate) {
                return candidate
            }
        }
        return "\(base)_copy_\(Int(Date().timeIntervalSince1970))"
    }
}
