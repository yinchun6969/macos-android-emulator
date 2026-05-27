import Foundation

public struct LaunchOptions: Sendable, Hashable {
    public let headless: Bool
    public let gpuMode: String
    public let memoryMB: Int?
    public let cores: Int?
    public let noSnapshotLoad: Bool
    public let noSnapshotSave: Bool
    public let noBootAnimation: Bool
    public let noMetrics: Bool
    public let noAudio: Bool
    public let cameraBack: String?
    public let cameraFront: String?
    public let readOnly: Bool
    public let port: Int?
    public let partitionSizeMB: Int?
    public let dpi: Int?
    public let vsyncRate: Int?
    public let phoneNumber: String?
    public let androidSerialNumber: String?
    public let writableSystem: Bool
    public let selinuxMode: String?
    public let skipADBAuth: Bool
    public let changeLocale: String?
    public let networkDelay: String?
    public let networkSpeed: String?
    public let dnsServers: String?
    public let bootProperties: [String: String]

    public init(
        headless: Bool = false,
        gpuMode: String = "auto",
        memoryMB: Int? = nil,
        cores: Int? = nil,
        noSnapshotLoad: Bool = false,
        noSnapshotSave: Bool = true,
        noBootAnimation: Bool = true,
        noMetrics: Bool = true,
        noAudio: Bool = true,
        cameraBack: String? = "none",
        cameraFront: String? = "none",
        readOnly: Bool = false,
        port: Int? = nil,
        partitionSizeMB: Int? = nil,
        dpi: Int? = nil,
        vsyncRate: Int? = nil,
        phoneNumber: String? = nil,
        androidSerialNumber: String? = nil,
        writableSystem: Bool = false,
        selinuxMode: String? = nil,
        skipADBAuth: Bool = true,
        changeLocale: String? = nil,
        networkDelay: String? = "none",
        networkSpeed: String? = "full",
        dnsServers: String? = "223.5.5.5,119.29.29.29,8.8.8.8,1.1.1.1",
        bootProperties: [String: String] = [:]
    ) {
        self.headless = headless
        self.gpuMode = gpuMode
        self.memoryMB = memoryMB
        self.cores = cores
        self.noSnapshotLoad = noSnapshotLoad
        self.noSnapshotSave = noSnapshotSave
        self.noBootAnimation = noBootAnimation
        self.noMetrics = noMetrics
        self.noAudio = noAudio
        self.cameraBack = cameraBack
        self.cameraFront = cameraFront
        self.readOnly = readOnly
        self.port = port
        self.partitionSizeMB = partitionSizeMB
        self.dpi = dpi
        self.vsyncRate = vsyncRate
        self.phoneNumber = phoneNumber
        self.androidSerialNumber = androidSerialNumber
        self.writableSystem = writableSystem
        self.selinuxMode = selinuxMode
        self.skipADBAuth = skipADBAuth
        self.changeLocale = changeLocale
        self.networkDelay = networkDelay
        self.networkSpeed = networkSpeed
        self.dnsServers = dnsServers
        self.bootProperties = bootProperties
    }

    public init(
        profile: RuntimeProfile,
        headless: Bool = false,
        memoryMB: Int? = nil,
        cores: Int? = nil,
        gpuMode: String? = nil,
        noSnapshotLoad: Bool = false,
        noAudio: Bool = true,
        readOnly: Bool = false,
        port: Int? = nil
    ) {
        self.init(
            headless: headless,
            gpuMode: gpuMode ?? profile.gpuMode,
            memoryMB: memoryMB ?? profile.memoryMB,
            cores: cores ?? profile.cores,
            noSnapshotLoad: noSnapshotLoad,
            noSnapshotSave: true,
            noBootAnimation: true,
            noMetrics: true,
            noAudio: noAudio,
            cameraBack: "none",
            cameraFront: "none",
            readOnly: readOnly,
            port: port,
            skipADBAuth: true
        )
    }

    public init(
        configuration: InstanceConfiguration,
        headless: Bool = false,
        noSnapshotLoad: Bool = false,
        readOnly: Bool = false,
        port: Int? = nil
    ) {
        self.init(
            headless: headless,
            gpuMode: configuration.runtimeProfile.gpuMode,
            memoryMB: configuration.runtimeProfile.memoryMB,
            cores: configuration.runtimeProfile.cores,
            noSnapshotLoad: noSnapshotLoad,
            noSnapshotSave: true,
            noBootAnimation: true,
            noMetrics: true,
            noAudio: true,
            cameraBack: "none",
            cameraFront: "none",
            readOnly: readOnly,
            port: port,
            partitionSizeMB: configuration.diskSizeMB,
            dpi: configuration.display.dpi,
            vsyncRate: configuration.display.fps,
            phoneNumber: configuration.identity.phoneNumber,
            androidSerialNumber: configuration.identity.serialNumber,
            writableSystem: configuration.rootEnabled,
            selinuxMode: configuration.rootEnabled ? "permissive" : nil,
            skipADBAuth: configuration.adbEnabled,
            changeLocale: configuration.resolvedSystemSettings.localeIdentifier,
            bootProperties: configuration.launchProperties
        )
    }
}

public final class EmulatorManager {
    private let sdk: AndroidSDK
    private let runner: ProcessRunning

    public init(sdk: AndroidSDK, runner: ProcessRunning = FoundationProcessRunner()) {
        self.sdk = sdk
        self.runner = runner
    }

    public func launch(avdName: String, options: LaunchOptions = LaunchOptions()) throws -> Int32 {
        guard let emulator = sdk.emulator else {
            throw MOSError.toolNotFound("emulator")
        }

        let arguments = Self.launchArguments(avdName: avdName, options: options)
        return try runner.launchDetached(emulator, arguments: arguments, environment: sdk.toolEnvironment)
    }

    public static func launchArguments(avdName: String, options: LaunchOptions) -> [String] {
        var arguments = ["-avd", avdName, "-gpu", options.gpuMode]

        if options.headless {
            arguments.append("-no-window")
        }
        if options.noSnapshotLoad {
            arguments.append("-no-snapshot-load")
        }
        if options.noSnapshotSave {
            arguments.append("-no-snapshot-save")
        }
        if options.noBootAnimation {
            arguments.append("-no-boot-anim")
        }
        if options.noMetrics {
            arguments.append("-no-metrics")
        }
        if options.noAudio {
            arguments.append("-no-audio")
        }
        if let cameraBack = options.cameraBack {
            arguments += ["-camera-back", cameraBack]
        }
        if let cameraFront = options.cameraFront {
            arguments += ["-camera-front", cameraFront]
        }
        if options.readOnly {
            arguments.append("-read-only")
        }
        if let port = options.port {
            arguments += ["-port", String(port)]
        }
        if let partitionSizeMB = options.partitionSizeMB {
            arguments += ["-partition-size", String(partitionSizeMB)]
        }
        if let dpi = options.dpi {
            arguments += ["-dpi-device", String(dpi)]
        }
        if let vsyncRate = options.vsyncRate {
            arguments += ["-vsync-rate", String(vsyncRate)]
        }
        if let phoneNumber = options.phoneNumber {
            let digits = phoneNumber.filter(\.isNumber)
            if !digits.isEmpty {
                arguments += ["-phone-number", digits]
            }
        }
        if let androidSerialNumber = options.androidSerialNumber {
            arguments += ["-android-serialno", androidSerialNumber]
        }
        if options.writableSystem {
            arguments.append("-writable-system")
        }
        if let selinuxMode = options.selinuxMode {
            arguments += ["-selinux", selinuxMode]
        }
        if options.skipADBAuth {
            arguments.append("-skip-adb-auth")
        }
        if let changeLocale = options.changeLocale, !changeLocale.isEmpty {
            arguments += ["-change-locale", changeLocale]
        }
        if let networkDelay = options.networkDelay, !networkDelay.isEmpty {
            arguments += ["-netdelay", networkDelay]
        }
        if let networkSpeed = options.networkSpeed, !networkSpeed.isEmpty {
            arguments += ["-netspeed", networkSpeed]
        }
        if let dnsServers = options.dnsServers, !dnsServers.isEmpty {
            arguments += ["-dns-server", dnsServers]
        }
        for key in options.bootProperties.keys.sorted() {
            guard let value = options.bootProperties[key], !value.isEmpty else {
                continue
            }
            arguments += ["-prop", "\(key)=\(value)"]
        }
        if let memoryMB = options.memoryMB {
            arguments += ["-memory", String(memoryMB)]
        }
        if let cores = options.cores {
            arguments += ["-cores", String(cores)]
        }

        return arguments
    }
}
