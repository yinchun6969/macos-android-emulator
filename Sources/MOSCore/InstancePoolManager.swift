import Foundation

public final class InstancePoolManager {
    private let avdManager: AVDManager
    private let emulatorManager: EmulatorManager

    public init(avdManager: AVDManager, emulatorManager: EmulatorManager) {
        self.avdManager = avdManager
        self.emulatorManager = emulatorManager
    }

    public func createPool(
        prefix: String,
        count: Int,
        package: String,
        device: String,
        profile: RuntimeProfile,
        display: DisplayProfile = .defaultPreset,
        diskSizeMB: Int? = nil,
        rootEnabled: Bool = false,
        adbEnabled: Bool = true,
        systemSettings: GuestSystemSettings = .default,
        force: Bool = false
    ) throws -> [AVD] {
        try validateCount(count)

        let names = InstanceNaming.names(prefix: prefix, count: count)
        for name in names {
            let spec = DeviceCatalog.randomSpec()
            let configuration = InstanceConfiguration.makeDefault(
                avdName: name,
                deviceName: name,
                deviceSpec: spec,
                display: display,
                runtimeProfile: profile,
                diskSizeMB: diskSizeMB,
                rootEnabled: rootEnabled,
                adbEnabled: adbEnabled,
                systemSettings: systemSettings
            )
            try avdManager.createAVD(
                configuration: configuration,
                package: package,
                device: device,
                force: force
            )
        }

        let all = try avdManager.listAVDs()
        let wanted = Set(names)
        return all.filter { wanted.contains($0.name) }
    }

    public func optimizePool(prefix: String, count: Int, profile: RuntimeProfile) throws -> [String] {
        try validateCount(count)

        let names = InstanceNaming.names(prefix: prefix, count: count)
        for name in names {
            try avdManager.optimizeAVD(name: name, profile: profile)
        }
        return names
    }

    public func copyPool(
        sourceName: String,
        prefix: String,
        count: Int,
        profile: RuntimeProfile? = nil,
        display: DisplayProfile? = nil,
        diskSizeMB: Int? = nil,
        rootEnabled: Bool? = nil,
        adbEnabled: Bool? = nil,
        systemSettings: GuestSystemSettings? = nil,
        force: Bool = false
    ) throws -> [InstanceConfiguration] {
        try validateCount(count)

        var configurations: [InstanceConfiguration] = []
        for name in InstanceNaming.names(prefix: prefix, count: count) {
            let configuration = try avdManager.copyAVD(
                sourceName: sourceName,
                destinationName: name,
                randomizedSpec: DeviceCatalog.randomSpec(),
                display: display,
                runtimeProfile: profile,
                diskSizeMB: diskSizeMB,
                rootEnabled: rootEnabled,
                adbEnabled: adbEnabled,
                force: force
            )
            if let systemSettings {
                let updated = InstanceConfiguration(
                    avdName: configuration.avdName,
                    deviceName: configuration.deviceName,
                    deviceSpec: configuration.deviceSpec,
                    identity: configuration.identity,
                    display: configuration.display,
                    runtimeProfile: configuration.runtimeProfile,
                    diskSizeMB: configuration.diskSizeMB,
                    rootEnabled: configuration.rootEnabled,
                    adbEnabled: configuration.adbEnabled,
                    systemImagePackage: configuration.resolvedSystemImagePackage,
                    systemSettings: systemSettings,
                    orientationRules: configuration.resolvedOrientationRules
                )
                try avdManager.applyConfiguration(updated)
                configurations.append(updated)
                continue
            }
            configurations.append(configuration)
        }
        return configurations
    }

    public func launchPool(
        prefix: String,
        count: Int,
        profile: RuntimeProfile,
        headless: Bool = false,
        noSnapshotLoad: Bool = false,
        allowOvercommit: Bool = false,
        basePort: Int = 5554,
        startDelaySeconds: TimeInterval = 2
    ) throws -> [LaunchedInstance] {
        try validateCount(count)
        try validateBasePort(basePort, count: count)

        let plan = ResourcePlanner.plan(requestedInstances: count, profile: profile)
        if !allowOvercommit && !plan.fitsRecommendedBudget {
            throw MOSError.invalidArgument(
                "Requested \(count) instances exceeds recommended max \(plan.recommendedMaxInstances) for \(profile.rawValue). Use --allow-overcommit to launch anyway."
            )
        }

        var launched: [LaunchedInstance] = []
        for (offset, name) in InstanceNaming.names(prefix: prefix, count: count).enumerated() {
            let port = basePort + offset * 2
            let options: LaunchOptions
            if let configuration = avdManager.configuration(for: name) {
                options = LaunchOptions(
                    configuration: configuration,
                    headless: headless,
                    noSnapshotLoad: noSnapshotLoad,
                    port: port
                )
            } else {
                options = LaunchOptions(
                    profile: profile,
                    headless: headless,
                    noSnapshotLoad: noSnapshotLoad,
                    readOnly: false,
                    port: port
                )
            }
            let pid = try emulatorManager.launch(avdName: name, options: options)
            launched.append(LaunchedInstance(avdName: name, pid: pid, port: port))

            if offset < count - 1 && startDelaySeconds > 0 {
                Thread.sleep(forTimeInterval: startDelaySeconds)
            }
        }

        return launched
    }

    private func validateCount(_ count: Int) throws {
        guard (1...64).contains(count) else {
            throw MOSError.invalidArgument("Instance count must be between 1 and 64.")
        }
    }

    private func validateBasePort(_ basePort: Int, count: Int) throws {
        let lastPort = basePort + max(0, count - 1) * 2
        guard basePort >= 5554, lastPort <= 5682, basePort.isMultiple(of: 2) else {
            throw MOSError.invalidArgument("Emulator ports must be even and within 5554...5682.")
        }
    }
}
