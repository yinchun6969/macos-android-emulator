import Foundation

public struct AndroidSDK: Sendable, Equatable {
    public let root: URL

    public init(root: URL) {
        self.root = root.standardizedFileURL
    }

    public var adb: URL? {
        executable("platform-tools/adb")
    }

    public var emulator: URL? {
        executable("emulator/emulator")
    }

    public var qemuImg: URL? {
        executable("emulator/qemu-img")
    }

    public var avdManager: URL? {
        firstExecutable(named: "avdmanager", under: commandLineToolDirectories())
    }

    public var sdkManager: URL? {
        firstExecutable(named: "sdkmanager", under: commandLineToolDirectories())
    }

    public var avdHome: URL {
        StorageLayout.preferredAVDHome()
    }

    public var emulatorHome: URL {
        StorageLayout.preferredEmulatorHome()
    }

    public var toolEnvironment: [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["ANDROID_HOME"] = root.path
        environment["ANDROID_SDK_ROOT"] = root.path
        environment["ANDROID_EMULATOR_HOME"] = emulatorHome.path
        environment["ANDROID_AVD_HOME"] = avdHome.path
        if environment["JAVA_HOME"]?.isEmpty ?? true,
           let bundledJBR = Self.androidStudioJBR(),
           FileManager.default.fileExists(atPath: bundledJBR.appendingPathComponent("bin/java").path) {
            environment["JAVA_HOME"] = bundledJBR.path
        }
        return environment
    }

    private static func androidStudioJBR() -> URL? {
        let candidates = [
            "/Applications/Android Studio.app/Contents/jbr/Contents/Home",
            "/Applications/Android Studio.app/Contents/jbr"
        ]
        return candidates
            .map { URL(fileURLWithPath: $0) }
            .first { FileManager.default.fileExists(atPath: $0.appendingPathComponent("bin/java").path) }
    }

    private func executable(_ relativePath: String) -> URL? {
        let url = root.appendingPathComponent(relativePath)
        return FileManager.default.isExecutableFile(atPath: url.path) ? url : nil
    }

    private func firstExecutable(named name: String, under directories: [URL]) -> URL? {
        directories
            .map { $0.appendingPathComponent(name) }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    private func commandLineToolDirectories() -> [URL] {
        let cmdlineTools = root.appendingPathComponent("cmdline-tools")
        var directories: [URL] = [
            cmdlineTools.appendingPathComponent("latest/bin"),
            root.appendingPathComponent("tools/bin")
        ]

        if let children = try? FileManager.default.contentsOfDirectory(
            at: cmdlineTools,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            let versioned = children
                .filter { $0.lastPathComponent != "latest" }
                .map { $0.appendingPathComponent("bin") }
                .sorted { $0.path > $1.path }
            directories.insert(contentsOf: versioned, at: 1)
        }

        return directories
    }
}

public enum DiagnosticStatus: String, Sendable, Equatable {
    case ok
    case warning
    case error
}

public struct SDKDiagnostic: Identifiable, Sendable, Equatable {
    public var id: String { name }

    public let name: String
    public let status: DiagnosticStatus
    public let message: String
    public let path: String?

    public init(name: String, status: DiagnosticStatus, message: String, path: String? = nil) {
        self.name = name
        self.status = status
        self.message = message
        self.path = path
    }
}

public enum AndroidSDKLocator {
    public static func discover(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: String = NSHomeDirectory()
    ) -> AndroidSDK? {
        candidateRoots(environment: environment, homeDirectory: homeDirectory)
            .map { AndroidSDK(root: $0) }
            .first { FileManager.default.fileExists(atPath: $0.root.path) }
    }

    public static func candidateRoots(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: String = NSHomeDirectory()
    ) -> [URL] {
        var paths: [String] = []
        if let androidHome = environment["ANDROID_HOME"], !androidHome.isEmpty {
            paths.append(androidHome)
        }
        if let sdkRoot = environment["ANDROID_SDK_ROOT"], !sdkRoot.isEmpty {
            paths.append(sdkRoot)
        }
        paths.append("\(homeDirectory)/Library/Android/sdk")

        return Array(NSOrderedSet(array: paths).array as? [String] ?? paths)
            .map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
    }

    public static func diagnostics(for sdk: AndroidSDK?) -> [SDKDiagnostic] {
        guard let sdk else {
            return [
                SDKDiagnostic(
                    name: "Android SDK",
                    status: .error,
                    message: "未找到 Android SDK。需要安装 Android Studio 或 Command-line Tools。",
                    path: nil
                )
            ]
        }

        let storageExists = FileManager.default.fileExists(atPath: sdk.avdHome.path)
        return [
            SDKDiagnostic(
                name: "Android SDK",
                status: .ok,
                message: "已找到 Android SDK。",
                path: sdk.root.path
            ),
            SDKDiagnostic(
                name: "Instance Storage",
                status: storageExists ? .ok : .warning,
                message: storageExists
                    ? "实例目录已就绪。"
                    : "实例目录尚未创建，创建或迁移第一个实例后会自动出现。",
                path: sdk.avdHome.path
            ),
            toolDiagnostic("adb", url: sdk.adb),
            toolDiagnostic("emulator", url: sdk.emulator),
            toolDiagnostic("avdmanager", url: sdk.avdManager),
            toolDiagnostic("sdkmanager", url: sdk.sdkManager),
            SDKDiagnostic(
                name: "AVD Home",
                status: storageExists ? .ok : .warning,
                message: storageExists
                    ? "已找到虚拟设备目录。"
                    : "暂未创建虚拟设备目录，创建第一个 AVD 后会自动出现。",
                path: sdk.avdHome.path
            )
        ]
    }

    private static func toolDiagnostic(_ name: String, url: URL?) -> SDKDiagnostic {
        if let url {
            SDKDiagnostic(name: name, status: .ok, message: "工具可用。", path: url.path)
        } else {
            SDKDiagnostic(name: name, status: .error, message: "工具缺失。", path: nil)
        }
    }
}
