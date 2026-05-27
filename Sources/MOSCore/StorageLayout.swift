import Foundation

public enum AppBrand {
    public static let displayName = "macOS"
    public static let bundleIdentifier = "com.macos.androidemulator"
    public static let externalVolumeName = "DDISK"
}

public enum StorageLayout {
    public static func legacyAVDHome(homeDirectory: String = NSHomeDirectory()) -> URL {
        URL(fileURLWithPath: homeDirectory)
            .appendingPathComponent(".android")
            .appendingPathComponent("avd")
    }

    public static func preferredEmulatorHome(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: String = NSHomeDirectory()
    ) -> URL {
        if let value = environment["ANDROID_EMULATOR_HOME"], !value.isEmpty {
            return URL(fileURLWithPath: (value as NSString).expandingTildeInPath)
        }
        if let value = environment["ANDROID_AVD_HOME"], !value.isEmpty {
            let avdHome = URL(fileURLWithPath: (value as NSString).expandingTildeInPath)
            return avdHome.deletingLastPathComponent()
        }

        let external = URL(fileURLWithPath: "/Volumes")
            .appendingPathComponent(AppBrand.externalVolumeName)
        if FileManager.default.fileExists(atPath: external.path) {
            return external
                .appendingPathComponent(AppBrand.displayName)
                .appendingPathComponent("Android")
        }

        return URL(fileURLWithPath: homeDirectory)
            .appendingPathComponent(".macOS")
            .appendingPathComponent("Android")
    }

    public static func preferredAVDHome(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: String = NSHomeDirectory()
    ) -> URL {
        if let value = environment["ANDROID_AVD_HOME"], !value.isEmpty {
            return URL(fileURLWithPath: (value as NSString).expandingTildeInPath)
        }
        return preferredEmulatorHome(
            environment: environment,
            homeDirectory: homeDirectory
        )
        .appendingPathComponent("avd")
    }

    public static func macroDirectory(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: String = NSHomeDirectory()
    ) -> URL {
        preferredEmulatorHome(
            environment: environment,
            homeDirectory: homeDirectory
        )
        .deletingLastPathComponent()
        .appendingPathComponent("Macros")
    }

    public static func ensureInstanceDirectories(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: String = NSHomeDirectory()
    ) throws {
        let emulatorHome = preferredEmulatorHome(
            environment: environment,
            homeDirectory: homeDirectory
        )
        let avdHome = preferredAVDHome(
            environment: environment,
            homeDirectory: homeDirectory
        )

        try FileManager.default.createDirectory(
            at: emulatorHome,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: avdHome,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: macroDirectory(environment: environment, homeDirectory: homeDirectory),
            withIntermediateDirectories: true
        )
    }
}
