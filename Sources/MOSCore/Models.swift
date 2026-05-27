import Foundation

public struct DeviceProfile: Sendable, Hashable, Codable {
    public let name: String
    public let avdName: String
    public let systemImagePackage: String
    public let deviceIdentifier: String
    public let memoryMB: Int
    public let cores: Int
    public let diskSizeMB: Int

    public init(
        name: String,
        avdName: String,
        systemImagePackage: String,
        deviceIdentifier: String,
        memoryMB: Int,
        cores: Int,
        diskSizeMB: Int
    ) {
        self.name = name
        self.avdName = avdName
        self.systemImagePackage = systemImagePackage
        self.deviceIdentifier = deviceIdentifier
        self.memoryMB = memoryMB
        self.cores = cores
        self.diskSizeMB = diskSizeMB
    }

    public static let appleSiliconDefaultImage = "system-images;android-35;google_apis;arm64-v8a"
    public static let appleSiliconGameCompatibilityImage = "system-images;android-28;google_apis;arm64-v8a"

    public static let appleSiliconDefault = DeviceProfile(
        name: "MOS Phone - Apple Silicon",
        avdName: "mos_phone_arm64",
        systemImagePackage: appleSiliconDefaultImage,
        deviceIdentifier: "pixel_7",
        memoryMB: RuntimeProfile.lean.memoryMB,
        cores: RuntimeProfile.lean.cores,
        diskSizeMB: RuntimeProfile.lean.diskSizeMB
    )
}

public enum RuntimeProfile: String, CaseIterable, Sendable, Hashable, Codable {
    case lean
    case balanced
    case performance
    case game

    public var displayName: String {
        switch self {
        case .lean:
            return "Lean"
        case .balanced:
            return "Balanced"
        case .performance:
            return "Performance"
        case .game:
            return "Game"
        }
    }

    public var memoryMB: Int {
        switch self {
        case .lean:
            return 2048
        case .balanced:
            return 3072
        case .performance:
            return 4096
        case .game:
            return 6144
        }
    }

    public var cores: Int {
        switch self {
        case .lean:
            return 2
        case .balanced:
            return 3
        case .performance:
            return 4
        case .game:
            return 4
        }
    }

    public var diskSizeMB: Int {
        switch self {
        case .lean:
            return 51200
        case .balanced:
            return 51200
        case .performance:
            return 51200
        case .game:
            return 51200
        }
    }

    public var vmHeapMB: Int {
        switch self {
        case .lean:
            return 192
        case .balanced:
            return 256
        case .performance:
            return 384
        case .game:
            return 512
        }
    }

    public var gpuMode: String {
        switch self {
        case .lean:
            return "swiftshader_indirect"
        case .balanced:
            return "auto"
        case .performance:
            return "host"
        case .game:
            return "host"
        }
    }

    public var hostOverheadMB: Int {
        switch self {
        case .lean:
            return 1024
        case .balanced:
            return 1280
        case .performance:
            return 1536
        case .game:
            return 1792
        }
    }

    public var avdConfigSettings: [String: String] {
        [
            "disk.dataPartition.size": "\(diskSizeMB)M",
            "fastboot.forceColdBoot": "no",
            "hw.audioInput": "no",
            "hw.audioOutput": "no",
            "hw.camera.back": "none",
            "hw.camera.front": "none",
            "hw.cpu.ncore": String(cores),
            "hw.gpu.enabled": "yes",
            "hw.gpu.mode": gpuMode,
            "hw.keyboard": "yes",
            "hw.ramSize": String(memoryMB),
            "showDeviceFrame": "no",
            "vm.heapSize": String(vmHeapMB)
        ]
    }
}

public struct MultiInstancePlan: Sendable, Hashable {
    public let requestedInstances: Int
    public let recommendedMaxInstances: Int
    public let physicalMemoryMB: Int
    public let reservedHostMemoryMB: Int
    public let perInstanceGuestMemoryMB: Int
    public let perInstanceEstimatedHostMB: Int
    public let totalEstimatedHostMB: Int

    public var fitsRecommendedBudget: Bool {
        requestedInstances <= recommendedMaxInstances
    }

    public init(
        requestedInstances: Int,
        recommendedMaxInstances: Int,
        physicalMemoryMB: Int,
        reservedHostMemoryMB: Int,
        perInstanceGuestMemoryMB: Int,
        perInstanceEstimatedHostMB: Int,
        totalEstimatedHostMB: Int
    ) {
        self.requestedInstances = requestedInstances
        self.recommendedMaxInstances = recommendedMaxInstances
        self.physicalMemoryMB = physicalMemoryMB
        self.reservedHostMemoryMB = reservedHostMemoryMB
        self.perInstanceGuestMemoryMB = perInstanceGuestMemoryMB
        self.perInstanceEstimatedHostMB = perInstanceEstimatedHostMB
        self.totalEstimatedHostMB = totalEstimatedHostMB
    }
}

public enum ResourcePlanner {
    public static func hostPhysicalMemoryMB() -> Int {
        Int(ProcessInfo.processInfo.physicalMemory / 1024 / 1024)
    }

    public static func reservedHostMemoryMB(for physicalMemoryMB: Int) -> Int {
        max(4096, physicalMemoryMB / 4)
    }

    public static func plan(
        requestedInstances: Int,
        profile: RuntimeProfile,
        physicalMemoryMB: Int = hostPhysicalMemoryMB()
    ) -> MultiInstancePlan {
        let reserved = reservedHostMemoryMB(for: physicalMemoryMB)
        let perInstance = profile.memoryMB + profile.hostOverheadMB
        let usable = max(0, physicalMemoryMB - reserved)
        let maxInstances = max(1, usable / perInstance)

        return MultiInstancePlan(
            requestedInstances: requestedInstances,
            recommendedMaxInstances: maxInstances,
            physicalMemoryMB: physicalMemoryMB,
            reservedHostMemoryMB: reserved,
            perInstanceGuestMemoryMB: profile.memoryMB,
            perInstanceEstimatedHostMB: perInstance,
            totalEstimatedHostMB: perInstance * requestedInstances
        )
    }
}

public enum InstanceNaming {
    public static func name(prefix: String, index: Int) -> String {
        "\(sanitizedPrefix(prefix))_\(String(format: "%02d", index))"
    }

    public static func names(prefix: String, count: Int) -> [String] {
        guard count > 0 else {
            return []
        }
        return (1...count).map { name(prefix: prefix, index: $0) }
    }

    private static func sanitizedPrefix(_ prefix: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let scalars = prefix.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "_"
        }
        let sanitized = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "_-"))
        return sanitized.isEmpty ? "mos_phone" : sanitized
    }
}

public struct AVD: Identifiable, Sendable, Hashable {
    public var id: String { name }

    public let name: String
    public let configPath: String?

    public init(name: String, configPath: String? = nil) {
        self.name = name
        self.configPath = configPath
    }
}

public enum AndroidDeviceState: String, Sendable, Hashable {
    case device
    case offline
    case unauthorized
    case unknown
}

public struct AndroidDevice: Identifiable, Sendable, Hashable {
    public var id: String { serial }

    public let serial: String
    public let state: AndroidDeviceState
    public let model: String?
    public let product: String?
    public let transportID: String?

    public init(
        serial: String,
        state: AndroidDeviceState,
        model: String? = nil,
        product: String? = nil,
        transportID: String? = nil
    ) {
        self.serial = serial
        self.state = state
        self.model = model
        self.product = product
        self.transportID = transportID
    }
}

public struct LaunchedInstance: Sendable, Hashable {
    public let avdName: String
    public let pid: Int32
    public let port: Int?

    public init(avdName: String, pid: Int32, port: Int?) {
        self.avdName = avdName
        self.pid = pid
        self.port = port
    }
}
