import Foundation
import MOSCore

extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

@discardableResult
func run() throws -> Int32 {
    let arguments = Array(CommandLine.arguments.dropFirst())

    guard let command = arguments.first else {
        printHelp()
        return 0
    }

    let rest = Array(arguments.dropFirst())

    switch command {
    case "help", "--help", "-h":
        printHelp()
    case "doctor":
        try doctor()
    case "list":
        try listAVDs()
    case "brands":
        listBrands()
    case "models":
        try listModels(rest)
    case "config":
        try showConfig(rest)
    case "set-config":
        try setConfig(rest)
    case "images":
        try listImages()
    case "plan":
        try planInstances(rest)
    case "licenses":
        try MOSPlatform.discover().avdManager.acceptLicenses()
        print("Android SDK licenses accepted.")
    case "install-image":
        guard let package = rest.first else {
            throw MOSError.invalidArgument("Usage: mosctl install-image <system-image-package>")
        }
        try MOSPlatform.discover().avdManager.installSystemImage(package)
        print("Installed: \(package)")
    case "create":
        try createAVD(rest)
    case "copy":
        try copyAVD(rest)
    case "copy-pool":
        try copyPool(rest)
    case "create-pool":
        try createPool(rest)
    case "optimize":
        try optimizeAVD(rest)
    case "optimize-pool":
        try optimizePool(rest)
    case "delete":
        guard let name = rest.first else {
            throw MOSError.invalidArgument("Usage: mosctl delete <avd-name>")
        }
        try MOSPlatform.discover().avdManager.deleteAVD(name: name)
        print("Deleted AVD: \(name)")
    case "switch-image":
        try switchImage(rest)
    case "boot":
        try boot(rest)
    case "boot-pool":
        try bootPool(rest)
    case "devices":
        try listDevices()
    case "inject-identity":
        try injectIdentity(rest)
    case "apply-system":
        try applySystem(rest)
    case "apply-orientation":
        try applyOrientation(rest)
    case "open-settings":
        try openAndroidSettings(rest)
    case "open-language":
        try openLanguageSettings(rest)
    case "open-accessibility":
        try openAccessibility(rest)
    case "open-battery":
        try openBattery(rest)
    case "repair-network":
        try repairNetwork(rest)
    case "root":
        try rootDevice(rest)
    case "migrate-storage":
        try migrateStorage(rest)
    case "rebuild-data":
        try rebuildData(rest)
    case "install-apk":
        try installAPK(rest)
    case "macro-list":
        try macroList()
    case "macro-play":
        try macroPlay(rest)
    case "stop":
        try stop(rest)
    default:
        throw MOSError.invalidArgument("Unknown command: \(command)\n\nRun `mosctl help` for usage.")
    }

    return 0
}

func doctor() throws {
    let sdk = AndroidSDKLocator.discover()
    for item in AndroidSDKLocator.diagnostics(for: sdk) {
        let marker: String
        switch item.status {
        case .ok:
            marker = "OK"
        case .warning:
            marker = "WARN"
        case .error:
            marker = "ERR"
        }

        if let path = item.path {
            print("[\(marker)] \(item.name): \(item.message) \(path)")
        } else {
            print("[\(marker)] \(item.name): \(item.message)")
        }
    }
}

func listAVDs() throws {
    let avds = try MOSPlatform.discover().avdManager.listAVDs()
    if avds.isEmpty {
        print("No AVDs found.")
        return
    }

    for avd in avds {
        print(avd.name)
    }
}

func listBrands() {
    for brand in DeviceCatalog.brands {
        print(brand)
    }
}

func listModels(_ args: [String]) throws {
    guard let brand = firstPositional(args, valueOptions: valueOptions) else {
        throw MOSError.invalidArgument("Usage: mosctl models <brand>")
    }

    for spec in DeviceCatalog.models(for: brand) {
        print("\(spec.modelName)\t\(spec.modelCode)\t\(spec.gpuHigh)")
    }
}

func showConfig(_ args: [String]) throws {
    guard let name = firstPositional(args, valueOptions: valueOptions) else {
        throw MOSError.invalidArgument("Usage: mosctl config <avd-name>")
    }

    guard let configuration = try MOSPlatform.discover().avdManager.configuration(for: name) else {
        throw MOSError.invalidArgument("No macOS instance config found for \(name).")
    }

    let data = try JSONEncoder.pretty.encode(configuration)
    print(String(data: data, encoding: .utf8) ?? "{}")
}

func setConfig(_ args: [String]) throws {
    guard let name = firstPositional(args, valueOptions: valueOptions) else {
        throw MOSError.invalidArgument("Usage: mosctl set-config <avd-name> [--display <WxH@DPI>] [--fps <n>] [--disk <mb>] [--profile <profile>] [--memory <mb>] [--cores <n>] [--gpu <mode>] [--root|--no-root] [--adb|--no-adb] [--locale zh-CN] [--accessibility] [--accessibility-service pkg/.Service] [--keep-battery-optimization] [--no-stay-awake]")
    }

    let platform = try MOSPlatform.discover()
    guard let current = platform.avdManager.configuration(for: name) else {
        throw MOSError.invalidArgument("No macOS instance config found for \(name).")
    }

    let requestedProfile = try runtimeProfileIfPresent(in: args)
    let updated = InstanceConfiguration(
        avdName: current.avdName,
        deviceName: current.deviceName,
        deviceSpec: current.deviceSpec,
        identity: current.identity,
        display: try displayProfileIfPresent(in: args, base: current.display) ?? current.display,
        runtimeProfile: requestedProfile ?? current.runtimeProfile,
        memoryMBOverride: try option("--memory", in: args).flatMap(Int.init) ?? (requestedProfile == nil ? current.memoryMBOverride : nil),
        coresOverride: try option("--cores", in: args).flatMap(Int.init) ?? (requestedProfile == nil ? current.coresOverride : nil),
        gpuModeOverride: try option("--gpu", in: args) ?? (requestedProfile == nil ? current.gpuModeOverride : nil),
        diskSizeMB: try option("--disk", in: args).flatMap(Int.init) ?? current.diskSizeMB,
        rootEnabled: flag("--root", in: args) ? true : flag("--no-root", in: args) ? false : current.rootEnabled,
        adbEnabled: flag("--adb", in: args) ? true : flag("--no-adb", in: args) ? false : current.adbEnabled,
        systemImagePackage: try option("--package", in: args) ?? current.resolvedSystemImagePackage,
        systemSettings: try systemSettingsIfPresent(in: args) ?? current.resolvedSystemSettings,
        orientationRules: current.resolvedOrientationRules
    )
    try platform.avdManager.applyConfiguration(updated)
    print("Saved config for \(name).")
}

func listImages() throws {
    let images = try MOSPlatform.discover().avdManager.installedSystemImages()
    if images.isEmpty {
        print("No installed Android system images found.")
        return
    }

    for image in images {
        print(image)
    }
}

func planInstances(_ args: [String]) throws {
    guard let rawCount = positionalArguments(args, valueOptions: valueOptions).first,
          let count = Int(rawCount)
    else {
            throw MOSError.invalidArgument("Usage: mosctl plan <count> [--profile lean|balanced|performance|game]")
    }

    let profile = try runtimeProfile(in: args)
    let plan = ResourcePlanner.plan(requestedInstances: count, profile: profile)
    print("profile: \(profile.rawValue)")
    print("physicalMemoryMB: \(plan.physicalMemoryMB)")
    print("reservedHostMemoryMB: \(plan.reservedHostMemoryMB)")
    print("perInstanceGuestMemoryMB: \(plan.perInstanceGuestMemoryMB)")
    print("perInstanceEstimatedHostMB: \(plan.perInstanceEstimatedHostMB)")
    print("totalEstimatedHostMB: \(plan.totalEstimatedHostMB)")
    print("recommendedMaxInstances: \(plan.recommendedMaxInstances)")
    print("fitsRecommendedBudget: \(plan.fitsRecommendedBudget ? "yes" : "no")")
}

func createAVD(_ args: [String]) throws {
    guard let name = firstPositional(args, valueOptions: valueOptions) else {
        throw MOSError.invalidArgument(
            "Usage: mosctl create <avd-name> [--package <system-image-package>] [--device <device-id>] [--profile lean|balanced|performance|game] [--force]"
        )
    }

    let defaultProfile = DeviceProfile.appleSiliconDefault
    let runtimeProfile = try runtimeProfile(in: args)
    let package = try option("--package", in: args) ?? defaultProfile.systemImagePackage
    let device = try option("--device", in: args) ?? defaultProfile.deviceIdentifier
    let spec = try deviceSpec(in: args, randomDefault: flag("--random-model", in: args))
    let display = try displayProfile(in: args)
    let diskSizeMB = try option("--disk", in: args).flatMap(Int.init)
    let rootEnabled = flag("--root", in: args)
    let adbEnabled = !flag("--no-adb", in: args)
    let systemSettings = try systemSettings(in: args)
    let force = flag("--force", in: args)
    let configuration = InstanceConfiguration.makeDefault(
        avdName: name,
        deviceName: try option("--display-name", in: args) ?? name,
        deviceSpec: spec,
        display: display,
        runtimeProfile: runtimeProfile,
        memoryMBOverride: try option("--memory", in: args).flatMap(Int.init),
        coresOverride: try option("--cores", in: args).flatMap(Int.init),
        gpuModeOverride: try option("--gpu", in: args),
        diskSizeMB: diskSizeMB,
        rootEnabled: rootEnabled,
        adbEnabled: adbEnabled,
        systemImagePackage: package,
        systemSettings: systemSettings
    )

    let platform = try MOSPlatform.discover()
    try platform.avdManager.createAVD(
        configuration: configuration,
        package: package,
        device: device,
        force: force
    )
    print("Created AVD: \(name) profile=\(runtimeProfile.rawValue)")
    print("model: \(configuration.deviceSpec.brand) \(configuration.deviceSpec.modelName) \(configuration.deviceSpec.modelCode)")
    print("display: \(configuration.display.width)x\(configuration.display.height) dpi:\(configuration.display.dpi) fps:\(configuration.display.fps)")
    print("diskGB: \(configuration.diskSizeMB / 1024)")
    print("imei: \(configuration.identity.imei)")
    print("config: \(platform.avdManager.avdDirectory(named: name).appendingPathComponent(InstanceConfigurationStore.fileName).path)")
}

func copyAVD(_ args: [String]) throws {
    let positionals = positionalArguments(args, valueOptions: valueOptions)
    guard positionals.count >= 2 else {
        throw MOSError.invalidArgument(
            "Usage: mosctl copy <source-avd> <destination-avd> [--profile <profile>] [--display <WxH@DPI>] [--fps <n>] [--disk <mb>] [--root|--no-root] [--adb|--no-adb] [--force]"
        )
    }

    let profile = try runtimeProfileIfPresent(in: args)
    let display = try displayProfileIfPresent(in: args)
    let diskSizeMB = try option("--disk", in: args).flatMap(Int.init)
    let rootEnabled = flag("--root", in: args) ? true : flag("--no-root", in: args) ? false : nil
    let adbEnabled = flag("--adb", in: args) ? true : flag("--no-adb", in: args) ? false : nil
    let systemSettings = try systemSettingsIfPresent(in: args)
    let configuration = try MOSPlatform.discover().avdManager.copyAVD(
        sourceName: positionals[0],
        destinationName: positionals[1],
        randomizedSpec: DeviceCatalog.randomSpec(),
        display: display,
        runtimeProfile: profile,
        memoryMBOverride: try option("--memory", in: args).flatMap(Int.init),
        coresOverride: try option("--cores", in: args).flatMap(Int.init),
        gpuModeOverride: try option("--gpu", in: args),
        diskSizeMB: diskSizeMB,
        rootEnabled: rootEnabled,
        adbEnabled: adbEnabled,
        force: flag("--force", in: args)
    )
    if let systemSettings {
        let updated = InstanceConfiguration(
            avdName: configuration.avdName,
            deviceName: configuration.deviceName,
            deviceSpec: configuration.deviceSpec,
            identity: configuration.identity,
            display: configuration.display,
            runtimeProfile: configuration.runtimeProfile,
            memoryMBOverride: configuration.memoryMBOverride,
            coresOverride: configuration.coresOverride,
            gpuModeOverride: configuration.gpuModeOverride,
            diskSizeMB: configuration.diskSizeMB,
            rootEnabled: configuration.rootEnabled,
            adbEnabled: configuration.adbEnabled,
            systemImagePackage: configuration.resolvedSystemImagePackage,
            systemSettings: systemSettings,
            orientationRules: configuration.resolvedOrientationRules
        )
        try MOSPlatform.discover().avdManager.applyConfiguration(updated)
    }

    print("Copied \(positionals[0]) -> \(positionals[1])")
    print("randomModel: \(configuration.deviceSpec.brand) \(configuration.deviceSpec.modelName) \(configuration.deviceSpec.modelCode)")
    print("imei: \(configuration.identity.imei)")
}

func copyPool(_ args: [String]) throws {
    let positionals = positionalArguments(args, valueOptions: valueOptions)
    guard positionals.count >= 3, let count = Int(positionals[2]) else {
        throw MOSError.invalidArgument(
            "Usage: mosctl copy-pool <source-avd> <prefix> <count> [--profile <profile>] [--display <WxH@DPI>] [--fps <n>] [--disk <mb>] [--root|--no-root] [--adb|--no-adb] [--force]"
        )
    }

    let profile = try runtimeProfileIfPresent(in: args)
    let configurations = try MOSPlatform.discover().instancePoolManager.copyPool(
        sourceName: positionals[0],
        prefix: positionals[1],
        count: count,
        profile: profile,
        display: try displayProfileIfPresent(in: args),
        diskSizeMB: try option("--disk", in: args).flatMap(Int.init),
        rootEnabled: flag("--root", in: args) ? true : flag("--no-root", in: args) ? false : nil,
        adbEnabled: flag("--adb", in: args) ? true : flag("--no-adb", in: args) ? false : nil,
        systemSettings: try systemSettingsIfPresent(in: args),
        force: flag("--force", in: args)
    )

    print("Copied \(configurations.count) instances from \(positionals[0]).")
    for configuration in configurations {
        print("\(configuration.avdName)\t\(configuration.deviceSpec.brand) \(configuration.deviceSpec.modelName)\timei:\(configuration.identity.imei)")
    }
}

func createPool(_ args: [String]) throws {
    let positionals = positionalArguments(args, valueOptions: valueOptions)
    guard positionals.count >= 2, let count = Int(positionals[1]) else {
        throw MOSError.invalidArgument(
            "Usage: mosctl create-pool <prefix> <count> [--profile lean|balanced|performance|game] [--package <system-image-package>] [--device <device-id>] [--force]"
        )
    }

    let defaultProfile = DeviceProfile.appleSiliconDefault
    let runtimeProfile = try runtimeProfile(in: args)
    let package = try option("--package", in: args) ?? defaultProfile.systemImagePackage
    let device = try option("--device", in: args) ?? defaultProfile.deviceIdentifier
    let display = try displayProfile(in: args)
    let diskSizeMB = try option("--disk", in: args).flatMap(Int.init)
    let rootEnabled = flag("--root", in: args)
    let adbEnabled = !flag("--no-adb", in: args)
    let systemSettings = try systemSettings(in: args)
    let force = flag("--force", in: args)
    let plan = ResourcePlanner.plan(requestedInstances: count, profile: runtimeProfile)

    let created = try MOSPlatform.discover().instancePoolManager.createPool(
        prefix: positionals[0],
        count: count,
        package: package,
        device: device,
        profile: runtimeProfile,
        display: display,
        diskSizeMB: diskSizeMB,
        rootEnabled: rootEnabled,
        adbEnabled: adbEnabled,
        systemSettings: systemSettings,
        force: force
    )

    print("Created \(created.count) AVDs with profile=\(runtimeProfile.rawValue).")
    print("Recommended max for this host/profile: \(plan.recommendedMaxInstances)")
    for avd in created {
        print(avd.name)
    }
}

func switchImage(_ args: [String]) throws {
    let positionals = positionalArguments(args, valueOptions: valueOptions)
    guard positionals.count >= 2 else {
        throw MOSError.invalidArgument("Usage: mosctl switch-image <avd-name> <system-image-package> [--device <device-id>]")
    }

    let platform = try MOSPlatform.discover()
    let device = try option("--device", in: args) ?? DeviceProfile.appleSiliconDefault.deviceIdentifier
    let backup = try platform.avdManager.switchSystemImage(name: positionals[0], package: positionals[1], device: device)
    print("Switched \(positionals[0]) to \(positionals[1]).")
    print("Backup: \(backup.path)")
}

func optimizeAVD(_ args: [String]) throws {
    guard let name = firstPositional(args, valueOptions: valueOptions) else {
        throw MOSError.invalidArgument("Usage: mosctl optimize <avd-name> [--profile lean|balanced|performance|game]")
    }

    let profile = try runtimeProfile(in: args)
    try MOSPlatform.discover().avdManager.optimizeAVD(name: name, profile: profile)
    print("Optimized AVD: \(name) profile=\(profile.rawValue)")
}

func optimizePool(_ args: [String]) throws {
    let positionals = positionalArguments(args, valueOptions: valueOptions)
    guard positionals.count >= 2, let count = Int(positionals[1]) else {
        throw MOSError.invalidArgument("Usage: mosctl optimize-pool <prefix> <count> [--profile lean|balanced|performance|game]")
    }

    let profile = try runtimeProfile(in: args)
    let names = try MOSPlatform.discover().instancePoolManager.optimizePool(
        prefix: positionals[0],
        count: count,
        profile: profile
    )
    print("Optimized \(names.count) AVDs with profile=\(profile.rawValue).")
    for name in names {
        print(name)
    }
}

func boot(_ args: [String]) throws {
    guard let name = firstPositional(args, valueOptions: valueOptions) else {
        throw MOSError.invalidArgument(
            "Usage: mosctl boot <avd-name> [--profile lean|balanced|performance|game] [--headless] [--gpu <auto|host|software|swiftshader_indirect>] [--memory <mb>] [--cores <n>] [--port <n>] [--read-only] [--no-snapshot]"
        )
    }

    let platform = try MOSPlatform.discover()
    let profile = try runtimeProfile(in: args)
    let options: LaunchOptions
    let effectiveProfile: RuntimeProfile
    if let configuration = platform.avdManager.configuration(for: name),
       try option("--memory", in: args) == nil,
       try option("--cores", in: args) == nil,
       try option("--gpu", in: args) == nil {
        effectiveProfile = configuration.runtimeProfile
        options = LaunchOptions(
            configuration: configuration,
            headless: flag("--headless", in: args),
            noSnapshotLoad: flag("--no-snapshot", in: args),
            readOnly: flag("--read-only", in: args),
            port: try option("--port", in: args).flatMap(Int.init)
        )
    } else {
        effectiveProfile = profile
        options = LaunchOptions(
            profile: profile,
            headless: flag("--headless", in: args),
            memoryMB: try option("--memory", in: args).flatMap(Int.init),
            cores: try option("--cores", in: args).flatMap(Int.init),
            gpuMode: try option("--gpu", in: args),
            noSnapshotLoad: flag("--no-snapshot", in: args),
            noAudio: !flag("--audio", in: args),
            readOnly: flag("--read-only", in: args),
            port: try option("--port", in: args).flatMap(Int.init)
        )
    }

    let pid = try platform.emulatorManager.launch(avdName: name, options: options)
    print("Started \(name) with pid \(pid), profile=\(effectiveProfile.rawValue).")
}

func bootPool(_ args: [String]) throws {
    let positionals = positionalArguments(args, valueOptions: valueOptions)
    guard positionals.count >= 2, let count = Int(positionals[1]) else {
        throw MOSError.invalidArgument(
            "Usage: mosctl boot-pool <prefix> <count> [--profile lean|balanced|performance|game] [--headless] [--base-port <even-port>] [--start-delay <seconds>] [--no-snapshot] [--allow-overcommit]"
        )
    }

    let profile = try runtimeProfile(in: args)
    let plan = ResourcePlanner.plan(requestedInstances: count, profile: profile)
    let basePort = try option("--base-port", in: args).flatMap(Int.init) ?? 5554
    let startDelay = try option("--start-delay", in: args).flatMap(Double.init) ?? 2

    let launched = try MOSPlatform.discover().instancePoolManager.launchPool(
        prefix: positionals[0],
        count: count,
        profile: profile,
        headless: flag("--headless", in: args),
        noSnapshotLoad: flag("--no-snapshot", in: args),
        allowOvercommit: flag("--allow-overcommit", in: args),
        basePort: basePort,
        startDelaySeconds: startDelay
    )

    print("Started \(launched.count) instances, profile=\(profile.rawValue), recommendedMax=\(plan.recommendedMaxInstances).")
    for instance in launched {
        let port = instance.port.map { " port:\($0)" } ?? ""
        print("\(instance.avdName)\tpid:\(instance.pid)\(port)")
    }
}

func listDevices() throws {
    let devices = try MOSPlatform.discover().adbManager.devices()
    if devices.isEmpty {
        print("No adb devices found.")
        return
    }

    for device in devices {
        let model = device.model.map { " model:\($0)" } ?? ""
        let product = device.product.map { " product:\($0)" } ?? ""
        print("\(device.serial)\t\(device.state.rawValue)\(model)\(product)")
    }
}

func injectIdentity(_ args: [String]) throws {
    guard args.count >= 2 else {
        throw MOSError.invalidArgument("Usage: mosctl inject-identity <serial|auto> <avd-name>")
    }

    let platform = try MOSPlatform.discover()
    let serial = try resolveSerial(args[0], adbManager: platform.adbManager)
    guard let configuration = platform.avdManager.configuration(for: args[1]) else {
        throw MOSError.invalidArgument("No macOS instance config found for \(args[1]).")
    }
    try platform.adbManager.applyVirtualIdentity(serial: serial, configuration: configuration)
    print("Injected virtual identity for \(args[1]) on \(serial).")
}

func applySystem(_ args: [String]) throws {
    guard args.count >= 2 else {
        throw MOSError.invalidArgument("Usage: mosctl apply-system <serial|auto> <avd-name>")
    }

    let platform = try MOSPlatform.discover()
    let serial = try resolveSerial(args[0], adbManager: platform.adbManager)
    guard let configuration = platform.avdManager.configuration(for: args[1]) else {
        throw MOSError.invalidArgument("No macOS instance config found for \(args[1]).")
    }
    try platform.adbManager.applyVirtualIdentity(serial: serial, configuration: configuration)
    try platform.adbManager.applyGuestSystemSettings(serial: serial, configuration: configuration)
    print("Applied system settings for \(args[1]) on \(serial).")
}

func applyOrientation(_ args: [String]) throws {
    guard args.count >= 2 else {
        throw MOSError.invalidArgument("Usage: mosctl apply-orientation <serial|auto> <avd-name>")
    }

    let platform = try MOSPlatform.discover()
    let serial = try resolveSerial(args[0], adbManager: platform.adbManager)
    guard let configuration = platform.avdManager.configuration(for: args[1]) else {
        throw MOSError.invalidArgument("No macOS instance config found for \(args[1]).")
    }
    let packageName = try platform.adbManager.foregroundPackage(serial: serial) ?? ""
    let shouldLandscape = configuration.resolvedOrientationRules.contains {
        $0.orientation == .landscape && $0.packageName == packageName
    }
    if shouldLandscape {
        try platform.adbManager.setAppOrientation(serial: serial, landscape: true)
        print("Applied landscape for \(packageName).")
    } else {
        try platform.adbManager.setAppOrientation(serial: serial, landscape: false)
        print("Applied portrait for \(packageName.isEmpty ? "current app" : packageName).")
    }
}

func openAccessibility(_ args: [String]) throws {
    let requested = args.first ?? "auto"
    let platform = try MOSPlatform.discover()
    let serial = try resolveSerial(requested, adbManager: platform.adbManager)
    try platform.adbManager.openAccessibilitySettings(serial: serial)
    print("Opened Accessibility settings on \(serial).")
}

func openAndroidSettings(_ args: [String]) throws {
    let requested = args.first ?? "auto"
    let platform = try MOSPlatform.discover()
    let serial = try resolveSerial(requested, adbManager: platform.adbManager)
    try platform.adbManager.openAndroidSettings(serial: serial)
    print("Opened Android settings on \(serial).")
}

func openLanguageSettings(_ args: [String]) throws {
    let requested = args.first ?? "auto"
    let platform = try MOSPlatform.discover()
    let serial = try resolveSerial(requested, adbManager: platform.adbManager)
    try platform.adbManager.openLanguageSettings(serial: serial)
    print("Opened Language settings on \(serial).")
}

func openBattery(_ args: [String]) throws {
    let requested = args.first ?? "auto"
    let platform = try MOSPlatform.discover()
    let serial = try resolveSerial(requested, adbManager: platform.adbManager)
    try platform.adbManager.openBatteryOptimizationSettings(serial: serial)
    print("Opened Battery optimization settings on \(serial).")
}

func repairNetwork(_ args: [String]) throws {
    let requested = args.first ?? "auto"
    let platform = try MOSPlatform.discover()
    let serial = try resolveSerial(requested, adbManager: platform.adbManager)
    try platform.adbManager.stabilizeNetwork(serial: serial)
    print("Repaired network state on \(serial).")
}

func rootDevice(_ args: [String]) throws {
    let requested = args.first ?? "auto"
    let platform = try MOSPlatform.discover()
    let serial = try resolveSerial(requested, adbManager: platform.adbManager)
    try platform.adbManager.root(serial: serial)
    print("ADB root requested for \(serial).")
}

func migrateStorage(_ args: [String]) throws {
    let migrated = try MOSPlatform.discover().avdManager.migrateLegacyAVDs(force: flag("--force", in: args))
    if migrated.isEmpty {
        print("No legacy AVDs needed migration.")
    } else {
        print("Migrated \(migrated.count) AVDs to \(StorageLayout.preferredAVDHome().path):")
        for name in migrated {
            print(name)
        }
    }
}

func rebuildData(_ args: [String]) throws {
    guard let name = firstPositional(args, valueOptions: valueOptions) else {
        throw MOSError.invalidArgument("Usage: mosctl rebuild-data <avd-name>")
    }

    let backup = try MOSPlatform.discover().avdManager.rebuildDataDisk(named: name)
    print("Backed up old data disk for \(name): \(backup.path)")
    print("Boot the instance again to create a new data disk with the configured disk size.")
}

func installAPK(_ args: [String]) throws {
    guard args.count >= 2 else {
        throw MOSError.invalidArgument("Usage: mosctl install-apk <serial|auto> <apk-path>")
    }

    let platform = try MOSPlatform.discover()
    let serial = try resolveSerial(args[0], adbManager: platform.adbManager)
    try platform.adbManager.installAPK(serial: serial, apkPath: args[1])
    print("Installed \(args[1]) on \(serial).")
}

func macroList() throws {
    let scripts = try MacroScriptStore.list()
    for script in scripts {
        print("\(script.id.uuidString)\t\(script.name)\tsteps:\(script.steps.count)\tpackage:\(script.targetPackage)")
    }
}

func macroPlay(_ args: [String]) throws {
    guard args.count >= 2 else {
        throw MOSError.invalidArgument("Usage: mosctl macro-play <serial|auto> <script-id-or-name> [--repeat <n>] [--speed <n>]")
    }

    let platform = try MOSPlatform.discover()
    let serial = try resolveSerial(args[0], adbManager: platform.adbManager)
    let scripts = try MacroScriptStore.list()
    guard let script = scripts.first(where: { $0.id.uuidString == args[1] || $0.name == args[1] }) else {
        throw MOSError.invalidArgument("Macro not found: \(args[1])")
    }
    let repeatCount = try option("--repeat", in: args).flatMap(Int.init) ?? 1
    let speed = try option("--speed", in: args).flatMap(Double.init) ?? 1
    try platform.adbManager.playMacro(serial: serial, script: script, repeatCount: repeatCount, speed: speed)
    print("Played macro \(script.name) on \(serial).")
}

func stop(_ args: [String]) throws {
    guard let requestedSerial = args.first else {
        throw MOSError.invalidArgument("Usage: mosctl stop <serial|auto>")
    }

    let platform = try MOSPlatform.discover()
    let serial = try resolveSerial(requestedSerial, adbManager: platform.adbManager)
    try platform.adbManager.killEmulator(serial: serial)
    print("Stopped emulator \(serial).")
}

func resolveSerial(_ requestedSerial: String, adbManager: ADBManager) throws -> String {
    guard requestedSerial == "auto" else {
        return requestedSerial
    }

    guard let device = try adbManager.devices().first(where: { $0.state == .device }) else {
        throw MOSError.noRunningDevice
    }
    return device.serial
}

let valueOptions: Set<String> = [
    "--base-port",
    "--brand",
    "--cores",
    "--device",
    "--disk",
    "--display",
    "--display-name",
    "--fps",
    "--gpu",
    "--locale",
    "--memory",
    "--model",
    "--package",
    "--port",
    "--profile",
    "--repeat",
    "--speed",
    "--start-delay",
    "--accessibility-service"
]

func runtimeProfile(in args: [String], default defaultProfile: RuntimeProfile = .lean) throws -> RuntimeProfile {
    try runtimeProfileIfPresent(in: args) ?? defaultProfile
}

func runtimeProfileIfPresent(in args: [String]) throws -> RuntimeProfile? {
    guard let raw = try option("--profile", in: args) else {
        return nil
    }
    guard let profile = RuntimeProfile(rawValue: raw) else {
        throw MOSError.invalidArgument("Invalid profile: \(raw). Expected lean, balanced, performance, or game.")
    }
    return profile
}

func systemSettings(in args: [String]) throws -> GuestSystemSettings {
    try systemSettingsIfPresent(in: args) ?? .default
}

func systemSettingsIfPresent(in args: [String]) throws -> GuestSystemSettings? {
    let locale = try option("--locale", in: args)
    let accessibility = flag("--accessibility", in: args)
    let accessibilityService = try option("--accessibility-service", in: args)
    let keepBatteryOptimization = flag("--keep-battery-optimization", in: args)
    let noStayAwake = flag("--no-stay-awake", in: args)

    guard locale != nil || accessibility || accessibilityService != nil || keepBatteryOptimization || noStayAwake else {
        return nil
    }

    return GuestSystemSettings(
        localeIdentifier: locale ?? GuestSystemSettings.default.localeIdentifier,
        accessibilityEnabled: accessibility || accessibilityService != nil,
        accessibilityService: accessibilityService ?? "",
        batteryOptimizationDisabled: !keepBatteryOptimization,
        stayAwakeWhileCharging: !noStayAwake
    )
}

func deviceSpec(in args: [String], randomDefault: Bool = false) throws -> AndroidDeviceSpec {
    if randomDefault {
        return DeviceCatalog.randomSpec()
    }
    let brand = try option("--brand", in: args)
    let model = try option("--model", in: args)
    if let resolved = DeviceCatalog.resolve(brand: brand, modelName: model) {
        return resolved
    }
    if let brand, model == nil {
        return DeviceCatalog.models(for: brand).first ?? DeviceCatalog.defaultSpec
    }
    if let brand, let model {
        throw MOSError.invalidArgument("Unknown device model: \(brand) \(model). Run `mosctl models \(brand)`.")
    }
    return DeviceCatalog.defaultSpec
}

func displayProfile(in args: [String]) throws -> DisplayProfile {
    try displayProfileIfPresent(in: args) ?? .defaultPreset
}

func displayProfileIfPresent(in args: [String], base: DisplayProfile? = nil) throws -> DisplayProfile? {
    guard let raw = try option("--display", in: args) else {
        if let fps = try option("--fps", in: args).flatMap(Int.init) {
            let base = base ?? DisplayProfile.defaultPreset
            return DisplayProfile(
                name: base.name,
                category: base.category,
                width: base.width,
                height: base.height,
                dpi: base.dpi,
                fps: fps,
                frameRateVisible: base.frameRateVisible,
                autoRotate: base.autoRotate,
                highQuality: base.highQuality
            )
        }
        return nil
    }

    let normalized = raw
        .lowercased()
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "*", with: "x")
    let parts = normalized.split(separator: "@").map(String.init)
    let size = parts[0].split(separator: "x").compactMap { Int($0) }
    guard size.count == 2 else {
        throw MOSError.invalidArgument("Invalid display. Use --display 1600x900@240.")
    }
    let dpi = parts.count > 1 ? Int(parts[1]) : nil
    let fps = try option("--fps", in: args).flatMap(Int.init) ?? 60
    return DisplayProfile(
        name: "\(size[0]) x \(size[1]) \(dpi ?? 240) DPI",
        category: size[0] >= size[1] ? .tablet : .phone,
        width: size[0],
        height: size[1],
        dpi: dpi ?? 240,
        fps: fps
    )
}

func firstPositional(_ args: [String], valueOptions: Set<String> = []) -> String? {
    positionalArguments(args, valueOptions: valueOptions).first
}

func positionalArguments(_ args: [String], valueOptions: Set<String> = []) -> [String] {
    var result: [String] = []
    var shouldSkipNext = false

    for arg in args {
        if shouldSkipNext {
            shouldSkipNext = false
            continue
        }
        if valueOptions.contains(arg) {
            shouldSkipNext = true
            continue
        }
        if arg.hasPrefix("-") {
            continue
        }
        result.append(arg)
    }

    return result
}

func flag(_ name: String, in args: [String]) -> Bool {
    args.contains(name)
}

func option(_ name: String, in args: [String]) throws -> String? {
    guard let index = args.firstIndex(of: name) else {
        return nil
    }

    let valueIndex = args.index(after: index)
    guard valueIndex < args.endIndex, !args[valueIndex].hasPrefix("--") else {
        throw MOSError.invalidArgument("Missing value for \(name).")
    }

    return args[valueIndex]
}

func printHelp() {
    print(
        """
        macOS Android Emulator Controller

        Usage:
          mosctl doctor
          mosctl licenses
          mosctl images
          mosctl brands
          mosctl models <brand>
          mosctl config <avd-name>
          mosctl set-config <avd-name> [--display <WxH@DPI>] [--fps <n>] [--disk <mb>] [--profile <profile>] [--memory <mb>] [--cores <n>] [--gpu <mode>] [--root|--no-root] [--adb|--no-adb] [--locale zh-CN] [--accessibility] [--keep-battery-optimization] [--no-stay-awake]
          mosctl plan <count> [--profile lean|balanced|performance|game]
          mosctl migrate-storage [--force]
          mosctl install-image <system-image-package>
          mosctl list
          mosctl create <avd-name> [--brand <brand>] [--model <model>] [--display <WxH@DPI>] [--fps <n>] [--disk <mb>] [--root] [--no-adb] [--force]
          mosctl switch-image <avd-name> <system-image-package> [--device <device-id>]
          mosctl copy <source-avd> <destination-avd> [--display <WxH@DPI>] [--fps <n>] [--disk <mb>] [--root|--no-root] [--adb|--no-adb] [--force]
          mosctl copy-pool <source-avd> <prefix> <count> [--display <WxH@DPI>] [--disk <mb>] [--root|--no-root] [--adb|--no-adb] [--force]
          mosctl create-pool <prefix> <count> [--profile <profile>] [--display <WxH@DPI>] [--disk <mb>] [--root] [--no-adb] [--force]
          mosctl optimize <avd-name> [--profile <profile>]
          mosctl optimize-pool <prefix> <count> [--profile <profile>]
          mosctl rebuild-data <avd-name>
          mosctl boot <avd-name> [--profile <profile>] [--headless] [--gpu <mode>] [--memory <mb>] [--cores <n>] [--port <n>] [--read-only] [--no-snapshot]
          mosctl boot-pool <prefix> <count> [--profile <profile>] [--headless] [--base-port <even-port>] [--allow-overcommit]
          mosctl devices
          mosctl root <serial|auto>
          mosctl inject-identity <serial|auto> <avd-name>
          mosctl apply-system <serial|auto> <avd-name>
          mosctl apply-orientation <serial|auto> <avd-name>
          mosctl open-settings <serial|auto>
          mosctl open-language <serial|auto>
          mosctl open-accessibility <serial|auto>
          mosctl open-battery <serial|auto>
          mosctl repair-network <serial|auto>
          mosctl install-apk <serial|auto> <apk-path>
          mosctl macro-list
          mosctl macro-play <serial|auto> <script-id-or-name> [--repeat <n>] [--speed <n>]
          mosctl stop <serial|auto>
          mosctl delete <avd-name>

        Default Apple Silicon image:
          system-images;android-35;google_apis;arm64-v8a
        """
    )
}

do {
    exit(try run())
} catch {
    fputs("error: \(error)\n", stderr)
    exit(1)
}
