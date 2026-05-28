import Foundation

public final class AVDManager {
    private let sdk: AndroidSDK
    private let runner: ProcessRunning

    public init(sdk: AndroidSDK, runner: ProcessRunning = FoundationProcessRunner()) {
        self.sdk = sdk
        self.runner = runner
    }

    public func listAVDs() throws -> [AVD] {
        guard let emulator = sdk.emulator else {
            throw MOSError.toolNotFound("emulator")
        }

        let result = try runner
            .run(
                emulator,
                arguments: ["-list-avds"],
                environment: sdk.toolEnvironment,
                input: nil,
                timeout: 20
            )
            .requireSuccess()

        return result.stdout
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { AVD(name: $0, configPath: configPath(for: $0)) }
    }

    public func installedSystemImages() throws -> [String] {
        guard let sdkManager = sdk.sdkManager else {
            throw MOSError.toolNotFound("sdkmanager")
        }

        let result = try runner
            .run(
                sdkManager,
                arguments: ["--list_installed"],
                environment: sdk.toolEnvironment,
                input: nil,
                timeout: 60
            )
            .requireSuccess()

        return Self.parseInstalledSystemImages(result.stdout)
    }

    public func installSystemImage(_ package: String) throws {
        guard let sdkManager = sdk.sdkManager else {
            throw MOSError.toolNotFound("sdkmanager")
        }

        _ = try runner
            .run(
                sdkManager,
                arguments: [package],
                environment: sdk.toolEnvironment,
                input: "y\n",
                timeout: 1800
            )
            .requireSuccess()
    }

    public func acceptLicenses() throws {
        guard let sdkManager = sdk.sdkManager else {
            throw MOSError.toolNotFound("sdkmanager")
        }

        _ = try runner
            .run(
                sdkManager,
                arguments: ["--licenses"],
                environment: sdk.toolEnvironment,
                input: String(repeating: "y\n", count: 40),
                timeout: 600
            )
            .requireSuccess()
    }

    public func createAVD(
        name: String,
        package: String,
        device: String,
        force: Bool = false
    ) throws {
        guard let avdManager = sdk.avdManager else {
            throw MOSError.toolNotFound("avdmanager")
        }

        try StorageLayout.ensureInstanceDirectories()

        var arguments = [
            "create",
            "avd",
            "--name", name,
            "--package", package,
            "--device", device
        ]
        if force {
            arguments.append("--force")
        }

        _ = try runner
            .run(
                avdManager,
                arguments: arguments,
                environment: sdk.toolEnvironment,
                input: "no\n",
                timeout: 180
            )
            .requireSuccess()
    }

    public func createAVD(
        configuration: InstanceConfiguration,
        package: String,
        device: String,
        force: Bool = false
    ) throws {
        try createAVD(
            name: configuration.avdName,
            package: package,
            device: device,
            force: force
        )
        try applyConfiguration(configuration)
    }

    public func switchSystemImage(
        name: String,
        package: String,
        device: String = DeviceProfile.appleSiliconDefault.deviceIdentifier
    ) throws -> URL {
        let directory = avdDirectory(named: name)
        let ini = avdINI(named: name)
        let existingConfiguration = configuration(for: name)
        let backup = try backupExistingAVD(named: name)

        do {
            try createAVD(name: name, package: package, device: device, force: true)
            let configuration = InstanceConfiguration(
                avdName: existingConfiguration?.avdName ?? name,
                deviceName: existingConfiguration?.deviceName ?? name,
                deviceSpec: existingConfiguration?.deviceSpec ?? DeviceCatalog.defaultSpec,
                identity: existingConfiguration?.identity ?? VirtualIdentityGenerator.makeIdentity(),
                display: existingConfiguration?.display ?? .defaultPreset,
                runtimeProfile: existingConfiguration?.runtimeProfile ?? .game,
                memoryMBOverride: existingConfiguration?.memoryMBOverride,
                coresOverride: existingConfiguration?.coresOverride,
                gpuModeOverride: existingConfiguration?.gpuModeOverride,
                diskSizeMB: existingConfiguration?.diskSizeMB ?? RuntimeProfile.game.diskSizeMB,
                rootEnabled: existingConfiguration?.rootEnabled ?? false,
                adbEnabled: existingConfiguration?.adbEnabled ?? true,
                systemImagePackage: package,
                systemSettings: existingConfiguration?.resolvedSystemSettings ?? .default,
                orientationRules: existingConfiguration?.resolvedOrientationRules
            )
            try applyConfiguration(configuration)
            return backup
        } catch {
            if FileManager.default.fileExists(atPath: backup.path) {
                try? FileManager.default.removeItem(at: directory)
                try? FileManager.default.removeItem(at: ini)
                try? restoreBackup(backup, name: name)
            }
            throw error
        }
    }

    public func optimizeAVD(name: String, profile: RuntimeProfile) throws {
        let configURL = avdDirectory(named: name).appendingPathComponent("config.ini")
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            throw MOSError.invalidArgument("AVD config not found: \(configURL.path)")
        }

        try Self.mergeConfig(at: configURL, updates: profile.avdConfigSettings)
    }

    public func applyConfiguration(_ configuration: InstanceConfiguration) throws {
        let avdDirectory = avdDirectory(named: configuration.avdName)
        let configURL = avdDirectory.appendingPathComponent("config.ini")
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            throw MOSError.invalidArgument("AVD config not found: \(configURL.path)")
        }

        try Self.mergeConfig(at: configURL, updates: configuration.avdConfigSettings)
        try InstanceConfigurationStore.write(configuration, to: avdDirectory)
    }

    public func configuration(for name: String) -> InstanceConfiguration? {
        try? InstanceConfigurationStore.read(from: avdDirectory(named: name))
    }

    public func rebuildDataDisk(named name: String) throws -> URL {
        let directory = avdDirectory(named: name)
        guard FileManager.default.fileExists(atPath: directory.path) else {
            throw MOSError.invalidArgument("AVD directory not found: \(directory.path)")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let backupDirectory = directory.appendingPathComponent("data-backup-\(formatter.string(from: Date()))")
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)

        let dataFiles = [
            "userdata-qemu.img",
            "userdata-qemu.img.qcow2",
            "cache.img",
            "cache.img.qcow2",
            "encryptionkey.img",
            "encryptionkey.img.qcow2"
        ]

        for fileName in dataFiles {
            let source = directory.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: source.path) else {
                continue
            }
            try FileManager.default.moveItem(at: source, to: backupDirectory.appendingPathComponent(fileName))
        }

        let snapshots = directory.appendingPathComponent("snapshots")
        if FileManager.default.fileExists(atPath: snapshots.path) {
            try FileManager.default.moveItem(at: snapshots, to: backupDirectory.appendingPathComponent("snapshots"))
        }

        return backupDirectory
    }

    private func backupExistingAVD(named name: String) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let backupDirectory = sdk.avdHome.appendingPathComponent("\(name)-system-backup-\(formatter.string(from: Date()))")
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)

        let directory = avdDirectory(named: name)
        let ini = avdINI(named: name)
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.moveItem(at: directory, to: backupDirectory.appendingPathComponent("\(name).avd"))
        }
        if FileManager.default.fileExists(atPath: ini.path) {
            try FileManager.default.moveItem(at: ini, to: backupDirectory.appendingPathComponent("\(name).ini"))
        }
        return backupDirectory
    }

    private func restoreBackup(_ backupDirectory: URL, name: String) throws {
        let directoryBackup = backupDirectory.appendingPathComponent("\(name).avd")
        let iniBackup = backupDirectory.appendingPathComponent("\(name).ini")
        if FileManager.default.fileExists(atPath: directoryBackup.path) {
            try FileManager.default.moveItem(at: directoryBackup, to: avdDirectory(named: name))
        }
        if FileManager.default.fileExists(atPath: iniBackup.path) {
            try FileManager.default.moveItem(at: iniBackup, to: avdINI(named: name))
        }
    }

    public func copyAVD(
        sourceName: String,
        destinationName: String,
        randomizedSpec: AndroidDeviceSpec = DeviceCatalog.randomSpec(),
        display: DisplayProfile? = nil,
        runtimeProfile: RuntimeProfile? = nil,
        memoryMBOverride: Int? = nil,
        coresOverride: Int? = nil,
        gpuModeOverride: String? = nil,
        diskSizeMB: Int? = nil,
        rootEnabled: Bool? = nil,
        adbEnabled: Bool? = nil,
        force: Bool = false
    ) throws -> InstanceConfiguration {
        let sourceDirectory = avdDirectory(named: sourceName)
        let sourceINI = avdINI(named: sourceName)
        guard FileManager.default.fileExists(atPath: sourceDirectory.path) else {
            throw MOSError.invalidArgument("Source AVD directory not found: \(sourceDirectory.path)")
        }
        guard FileManager.default.fileExists(atPath: sourceINI.path) else {
            throw MOSError.invalidArgument("Source AVD ini not found: \(sourceINI.path)")
        }

        let destinationDirectory = avdDirectory(named: destinationName)
        let destinationINI = avdINI(named: destinationName)
        if FileManager.default.fileExists(atPath: destinationDirectory.path) ||
            FileManager.default.fileExists(atPath: destinationINI.path) {
            guard force else {
                throw MOSError.invalidArgument("Destination AVD already exists: \(destinationName). Use --force to overwrite.")
            }
            try? FileManager.default.removeItem(at: destinationDirectory)
            try? FileManager.default.removeItem(at: destinationINI)
        }

        try FileManager.default.copyItem(at: sourceDirectory, to: destinationDirectory)

        let sourceConfig = configuration(for: sourceName)
        let configuration = InstanceConfiguration.makeDefault(
            avdName: destinationName,
            deviceName: destinationName,
            deviceSpec: randomizedSpec,
            display: display ?? sourceConfig?.display ?? .defaultPreset,
            runtimeProfile: runtimeProfile ?? sourceConfig?.runtimeProfile ?? .lean,
            memoryMBOverride: memoryMBOverride ?? (runtimeProfile == nil ? sourceConfig?.memoryMBOverride : nil),
            coresOverride: coresOverride ?? (runtimeProfile == nil ? sourceConfig?.coresOverride : nil),
            gpuModeOverride: gpuModeOverride ?? (runtimeProfile == nil ? sourceConfig?.gpuModeOverride : nil),
            diskSizeMB: diskSizeMB ?? sourceConfig?.diskSizeMB,
            rootEnabled: rootEnabled ?? sourceConfig?.rootEnabled ?? false,
            adbEnabled: adbEnabled ?? sourceConfig?.adbEnabled ?? true,
            systemImagePackage: sourceConfig?.resolvedSystemImagePackage ?? DeviceProfile.appleSiliconDefaultImage,
            systemSettings: sourceConfig?.resolvedSystemSettings ?? .default,
            orientationRules: sourceConfig?.resolvedOrientationRules
        )

        try rewriteINI(
            sourceURL: sourceINI,
            destinationURL: destinationINI,
            name: destinationName,
            avdDirectory: destinationDirectory
        )
        try Self.mergeConfig(
            at: destinationDirectory.appendingPathComponent("config.ini"),
            updates: [
                "avd.id": destinationName,
                "avd.name": destinationName
            ]
        )
        try applyConfiguration(configuration)
        return configuration
    }

    @discardableResult
    public func migrateLegacyAVDs(force: Bool = false) throws -> [String] {
        let legacyHome = StorageLayout.legacyAVDHome()
        guard legacyHome.path != sdk.avdHome.path,
              FileManager.default.fileExists(atPath: legacyHome.path)
        else {
            return []
        }

        try StorageLayout.ensureInstanceDirectories()
        let children = try FileManager.default.contentsOfDirectory(
            at: legacyHome,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var migrated: [String] = []
        for iniURL in children where iniURL.pathExtension == "ini" {
            let name = iniURL.deletingPathExtension().lastPathComponent
            let sourceDirectory = legacyHome.appendingPathComponent("\(name).avd")
            let destinationINI = avdINI(named: name)
            let destinationDirectory = avdDirectory(named: name)
            guard FileManager.default.fileExists(atPath: sourceDirectory.path) else {
                continue
            }
            if FileManager.default.fileExists(atPath: destinationDirectory.path) ||
                FileManager.default.fileExists(atPath: destinationINI.path) {
                guard force else {
                    continue
                }
                try? FileManager.default.removeItem(at: destinationDirectory)
                try? FileManager.default.removeItem(at: destinationINI)
            }

            try FileManager.default.copyItem(at: sourceDirectory, to: destinationDirectory)
            try rewriteINI(
                sourceURL: iniURL,
                destinationURL: destinationINI,
                name: name,
                avdDirectory: destinationDirectory
            )
            let config = InstanceConfiguration.makeDefault(avdName: name, deviceName: name)
            try applyConfiguration(config)
            migrated.append(name)
        }

        return migrated
    }

    public func deleteAVD(name: String) throws {
        guard let avdManager = sdk.avdManager else {
            throw MOSError.toolNotFound("avdmanager")
        }

        _ = try runner
            .run(
                avdManager,
                arguments: ["delete", "avd", "--name", name],
                environment: sdk.toolEnvironment,
                input: nil,
                timeout: 120
            )
            .requireSuccess()
    }

    public func configPath(for name: String) -> String {
        avdDirectory(named: name).appendingPathComponent("config.ini").path
    }

    public func avdDirectory(named name: String) -> URL {
        sdk.avdHome.appendingPathComponent("\(name).avd")
    }

    public func avdINI(named name: String) -> URL {
        sdk.avdHome.appendingPathComponent("\(name).ini")
    }

    public static func parseInstalledSystemImages(_ output: String) -> [String] {
        output
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.hasPrefix("system-images;") else {
                    return nil
                }
                return trimmed.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
    }

    static func mergeConfig(at url: URL, updates: [String: String]) throws {
        let text = try String(contentsOf: url, encoding: .utf8)
        var values: [String: String] = [:]

        for line in text.split(whereSeparator: \.isNewline) {
            let raw = String(line)
            let pair = raw.split(separator: "=", maxSplits: 1).map(String.init)
            guard pair.count == 2 else {
                continue
            }
            values[pair[0]] = pair[1]
        }

        updates.forEach { key, value in
            values[key] = value
        }

        let merged = values
            .keys
            .sorted()
            .map { "\($0)=\(values[$0] ?? "")" }
            .joined(separator: "\n") + "\n"

        try merged.write(to: url, atomically: true, encoding: .utf8)
    }

    private func rewriteINI(
        sourceURL: URL,
        destinationURL: URL,
        name: String,
        avdDirectory: URL
    ) throws {
        let text = try String(contentsOf: sourceURL, encoding: .utf8)
        var values: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            let pair = String(line).split(separator: "=", maxSplits: 1).map(String.init)
            guard pair.count == 2 else {
                continue
            }
            values[pair[0]] = pair[1]
        }
        values["avd.ini.encoding"] = "UTF-8"
        values["path"] = avdDirectory.path
        values["path.rel"] = "avd/\(name).avd"

        let rewritten = values
            .keys
            .sorted()
            .map { "\($0)=\(values[$0] ?? "")" }
            .joined(separator: "\n") + "\n"
        try rewritten.write(to: destinationURL, atomically: true, encoding: .utf8)
    }
}
