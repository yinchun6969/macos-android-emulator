import Foundation

public enum ScreenCategory: String, CaseIterable, Sendable, Hashable, Codable {
    case tablet
    case phone
    case custom
}

public struct DisplayProfile: Identifiable, Sendable, Hashable, Codable {
    public var id: String { "\(width)x\(height)@\(dpi)" }

    public let name: String
    public let category: ScreenCategory
    public let width: Int
    public let height: Int
    public let dpi: Int
    public let fps: Int
    public let frameRateVisible: Bool
    public let autoRotate: Bool
    public let highQuality: Bool

    public init(
        name: String,
        category: ScreenCategory,
        width: Int,
        height: Int,
        dpi: Int,
        fps: Int,
        frameRateVisible: Bool = false,
        autoRotate: Bool = true,
        highQuality: Bool = false
    ) {
        self.name = name
        self.category = category
        self.width = width
        self.height = height
        self.dpi = dpi
        self.fps = fps
        self.frameRateVisible = frameRateVisible
        self.autoRotate = autoRotate
        self.highQuality = highQuality
    }

    public static let presets: [DisplayProfile] = [
        DisplayProfile(name: "720 x 1280 320 DPI", category: .phone, width: 720, height: 1280, dpi: 320, fps: 60),
        DisplayProfile(name: "720 x 1600 320 DPI", category: .phone, width: 720, height: 1600, dpi: 320, fps: 60),
        DisplayProfile(name: "1080 x 1920 420 DPI", category: .phone, width: 1080, height: 1920, dpi: 420, fps: 60),
        DisplayProfile(name: "1080 x 2400 420 DPI", category: .phone, width: 1080, height: 2400, dpi: 420, fps: 60),
        DisplayProfile(name: "1920 x 1080 280 DPI", category: .tablet, width: 1920, height: 1080, dpi: 280, fps: 60),
        DisplayProfile(name: "1600 x 900 240 DPI", category: .tablet, width: 1600, height: 900, dpi: 240, fps: 60),
        DisplayProfile(name: "1280 x 720 240 DPI", category: .tablet, width: 1280, height: 720, dpi: 240, fps: 60),
        DisplayProfile(name: "960 x 540 220 DPI", category: .tablet, width: 960, height: 540, dpi: 220, fps: 60)
    ]

    public static let defaultPreset = presets[0]
}

public struct VirtualIdentity: Sendable, Hashable, Codable {
    public let imei: String
    public let imsi: String
    public let androidId: String
    public let serialNumber: String
    public let wifiMacAddress: String
    public let phoneNumber: String

    public init(
        imei: String,
        imsi: String,
        androidId: String,
        serialNumber: String,
        wifiMacAddress: String,
        phoneNumber: String
    ) {
        self.imei = imei
        self.imsi = imsi
        self.androidId = androidId
        self.serialNumber = serialNumber
        self.wifiMacAddress = wifiMacAddress
        self.phoneNumber = phoneNumber
    }
}

public struct GuestSystemSettings: Sendable, Hashable, Codable {
    public let localeIdentifier: String
    public let accessibilityEnabled: Bool
    public let accessibilityService: String
    public let batteryOptimizationDisabled: Bool
    public let stayAwakeWhileCharging: Bool

    public init(
        localeIdentifier: String = "zh-CN",
        accessibilityEnabled: Bool = false,
        accessibilityService: String = "",
        batteryOptimizationDisabled: Bool = true,
        stayAwakeWhileCharging: Bool = true
    ) {
        self.localeIdentifier = localeIdentifier
        self.accessibilityEnabled = accessibilityEnabled
        self.accessibilityService = accessibilityService
        self.batteryOptimizationDisabled = batteryOptimizationDisabled
        self.stayAwakeWhileCharging = stayAwakeWhileCharging
    }

    public static let `default` = GuestSystemSettings()
}

public enum AppOrientation: String, Sendable, Hashable, Codable {
    case portrait
    case landscape
}

public struct AppOrientationRule: Identifiable, Sendable, Hashable, Codable {
    public var id: String { packageName }
    public let packageName: String
    public let orientation: AppOrientation

    public init(packageName: String, orientation: AppOrientation) {
        self.packageName = packageName
        self.orientation = orientation
    }
}

public enum VirtualIdentityGenerator {
    public static func makeIdentity(for spec: AndroidDeviceSpec = DeviceCatalog.defaultSpec) -> VirtualIdentity {
        let tac = spec.virtualTACPrefixes.randomElement() ?? "99000000"
        return VirtualIdentity(
            imei: makeIMEI(tacPrefix: tac),
            imsi: "4600" + randomDigits(count: 11),
            androidId: randomHex(count: 16),
            serialNumber: "MACOS" + randomAlphaNumeric(count: 10),
            wifiMacAddress: makeLocalMACAddress(),
            phoneNumber: "+8617" + randomDigits(count: 9)
        )
    }

    public static func makeIMEI(tacPrefix: String) -> String {
        let normalized = String(tacPrefix.filter(\.isNumber).prefix(8))
            .padding(toLength: 8, withPad: "0", startingAt: 0)
        let body = normalized + randomDigits(count: 6)
        return body + String(luhnCheckDigit(for: body))
    }

    public static func isValidIMEI(_ value: String) -> Bool {
        let digits = value.compactMap(\.wholeNumberValue)
        guard digits.count == 15 else {
            return false
        }
        let body = String(value.prefix(14))
        return digits[14] == luhnCheckDigit(for: body)
    }

    private static func luhnCheckDigit(for body: String) -> Int {
        let digits = body.compactMap(\.wholeNumberValue)
        let sum = digits.enumerated().reduce(0) { partial, item in
            let indexFromRight = digits.count - item.offset
            let shouldDouble = indexFromRight.isMultiple(of: 2)
            let value = shouldDouble ? item.element * 2 : item.element
            return partial + (value > 9 ? value - 9 : value)
        }
        return (10 - (sum % 10)) % 10
    }

    private static func randomDigits(count: Int) -> String {
        String((0..<count).map { _ in Character(String(Int.random(in: 0...9))) })
    }

    private static func randomHex(count: Int) -> String {
        let alphabet = Array("0123456789abcdef")
        return String((0..<count).map { _ in alphabet.randomElement() ?? "0" })
    }

    private static func randomAlphaNumeric(count: Int) -> String {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<count).map { _ in alphabet.randomElement() ?? "A" })
    }

    private static func makeLocalMACAddress() -> String {
        let bytes = [0x02] + (0..<5).map { _ in Int.random(in: 0...255) }
        return bytes.map { String(format: "%02x", $0) }.joined(separator: ":")
    }
}

public struct InstanceConfiguration: Sendable, Hashable, Codable {
    public let avdName: String
    public let deviceName: String
    public let deviceSpec: AndroidDeviceSpec
    public let identity: VirtualIdentity
    public let display: DisplayProfile
    public let runtimeProfile: RuntimeProfile
    public let diskSizeMB: Int
    public let rootEnabled: Bool
    public let adbEnabled: Bool
    public let systemImagePackage: String?
    public let systemSettings: GuestSystemSettings?
    public let orientationRules: [AppOrientationRule]?

    public init(
        avdName: String,
        deviceName: String,
        deviceSpec: AndroidDeviceSpec,
        identity: VirtualIdentity,
        display: DisplayProfile,
        runtimeProfile: RuntimeProfile,
        diskSizeMB: Int,
        rootEnabled: Bool,
        adbEnabled: Bool,
        systemImagePackage: String? = DeviceProfile.appleSiliconDefaultImage,
        systemSettings: GuestSystemSettings? = .default,
        orientationRules: [AppOrientationRule]? = nil
    ) {
        self.avdName = avdName
        self.deviceName = deviceName
        self.deviceSpec = deviceSpec
        self.identity = identity
        self.display = display
        self.runtimeProfile = runtimeProfile
        self.diskSizeMB = diskSizeMB
        self.rootEnabled = rootEnabled
        self.adbEnabled = adbEnabled
        self.systemImagePackage = systemImagePackage
        self.systemSettings = systemSettings
        self.orientationRules = orientationRules
    }

    public static func makeDefault(
        avdName: String,
        deviceName: String? = nil,
        deviceSpec: AndroidDeviceSpec = DeviceCatalog.defaultSpec,
        display: DisplayProfile = .defaultPreset,
        runtimeProfile: RuntimeProfile = .lean,
        diskSizeMB: Int? = nil,
        rootEnabled: Bool = false,
        adbEnabled: Bool = true,
        systemImagePackage: String = DeviceProfile.appleSiliconDefaultImage,
        systemSettings: GuestSystemSettings = .default,
        orientationRules: [AppOrientationRule]? = nil
    ) -> InstanceConfiguration {
        InstanceConfiguration(
            avdName: avdName,
            deviceName: deviceName ?? avdName,
            deviceSpec: deviceSpec,
            identity: VirtualIdentityGenerator.makeIdentity(for: deviceSpec),
            display: display,
            runtimeProfile: runtimeProfile,
            diskSizeMB: diskSizeMB ?? runtimeProfile.diskSizeMB,
            rootEnabled: rootEnabled,
            adbEnabled: adbEnabled,
            systemImagePackage: systemImagePackage,
            systemSettings: systemSettings,
            orientationRules: orientationRules
        )
    }

    public var resolvedSystemSettings: GuestSystemSettings {
        systemSettings ?? .default
    }

    public var resolvedSystemImagePackage: String {
        systemImagePackage ?? DeviceProfile.appleSiliconDefaultImage
    }

    public var resolvedOrientationRules: [AppOrientationRule] {
        orientationRules ?? [
            AppOrientationRule(packageName: "com.u1game.cabalm", orientation: .landscape)
        ]
    }

    public var avdConfigSettings: [String: String] {
        var settings = runtimeProfile.avdConfigSettings
        settings["avd.id"] = avdName
        settings["avd.name"] = avdName
        settings["disk.dataPartition.size"] = "\(diskSizeMB)M"
        settings["hw.device.manufacturer"] = deviceSpec.manufacturer
        settings["hw.device.name"] = deviceSpec.modelCode
        settings["hw.gsmModem"] = "yes"
        settings["hw.initialOrientation"] = display.width >= display.height ? "landscape" : "portrait"
        settings["hw.lcd.density"] = String(display.dpi)
        settings["hw.lcd.height"] = String(display.height)
        settings["hw.lcd.vsync"] = String(display.fps)
        settings["hw.lcd.width"] = String(display.width)
        settings["hw.mainKeys"] = "no"
        settings["hw.ramSize"] = String(runtimeProfile.memoryMB)
        settings["runtime.network.latency"] = "none"
        settings["runtime.network.speed"] = "full"
        return settings
    }

    public var launchProperties: [String: String] {
        [
            "ro.product.brand": deviceSpec.brand,
            "ro.product.manufacturer": deviceSpec.manufacturer,
            "ro.product.model": deviceSpec.modelName,
            "ro.product.name": deviceSpec.productName,
            "ro.product.device": deviceSpec.deviceName,
            "persist.macos.virtual.imei": identity.imei,
            "persist.macos.virtual.imsi": identity.imsi,
            "persist.macos.virtual.android_id": identity.androidId,
            "persist.macos.virtual.model_code": deviceSpec.modelCode
        ]
    }
}

public enum InstanceConfigurationStore {
    public static let fileName = ".macos-instance.json"

    public static func configurationURL(avdDirectory: URL) -> URL {
        avdDirectory.appendingPathComponent(fileName)
    }

    public static func read(from avdDirectory: URL) throws -> InstanceConfiguration {
        let data = try Data(contentsOf: configurationURL(avdDirectory: avdDirectory))
        return try JSONDecoder().decode(InstanceConfiguration.self, from: data)
    }

    public static func write(_ configuration: InstanceConfiguration, to avdDirectory: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(configuration)
        try data.write(to: configurationURL(avdDirectory: avdDirectory), options: .atomic)
    }
}
