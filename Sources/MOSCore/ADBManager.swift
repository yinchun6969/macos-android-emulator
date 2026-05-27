import Foundation

public final class ADBManager {
    private let sdk: AndroidSDK
    private let runner: ProcessRunning

    public init(sdk: AndroidSDK, runner: ProcessRunning = FoundationProcessRunner()) {
        self.sdk = sdk
        self.runner = runner
    }

    public func startServer() throws {
        guard let adb = sdk.adb else {
            throw MOSError.toolNotFound("adb")
        }
        _ = try runner
            .run(adb, arguments: ["start-server"], environment: sdk.toolEnvironment, input: nil, timeout: 20)
            .requireSuccess()
    }

    public func devices() throws -> [AndroidDevice] {
        guard let adb = sdk.adb else {
            throw MOSError.toolNotFound("adb")
        }
        let result = try runner
            .run(adb, arguments: ["devices", "-l"], environment: sdk.toolEnvironment, input: nil, timeout: 20)
            .requireSuccess()
        return Self.parseDevices(result.stdout)
    }

    public func installAPK(
        serial: String,
        apkPath: String,
        replace: Bool = true,
        grantPermissions: Bool = true,
        streaming: Bool = true
    ) throws {
        guard let adb = sdk.adb else {
            throw MOSError.toolNotFound("adb")
        }
        guard FileManager.default.fileExists(atPath: apkPath) else {
            throw MOSError.invalidArgument("APK not found: \(apkPath)")
        }

        var arguments = ["-s", serial, "install"]
        if replace {
            arguments.append("-r")
        }
        if grantPermissions {
            arguments.append("-g")
        }
        if streaming {
            arguments.append("--streaming")
        }
        arguments.append(apkPath)

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: apkPath)[.size] as? NSNumber)?.int64Value ?? 0
        // For large APKs (3GB+), use generous timeout: ~1MB/s transfer + 30min buffer
        let timeout = max(1800, TimeInterval(fileSize / (1024 * 1024)) + 1800)
        let result = try runner.run(adb, arguments: arguments, environment: sdk.toolEnvironment, input: nil, timeout: timeout)
        if result.succeeded {
            return
        }

        // First fallback: retry without streaming
        if streaming {
            let fallbackArguments = arguments.filter { $0 != "--streaming" }
            let retryResult = try runner
                .run(adb, arguments: fallbackArguments, environment: sdk.toolEnvironment, input: nil, timeout: timeout)
            if retryResult.succeeded {
                return
            }
        }

        // Second fallback: try with -t flag (force streamable install) for split APKs
        if !apkPath.hasSuffix(".apks") {
            var retryArguments = ["-s", serial, "install", "-t"]
            if replace { retryArguments.append("-r") }
            if grantPermissions { retryArguments.append("-g") }
            retryArguments.append(apkPath)
            let lastResult = try runner.run(adb, arguments: retryArguments, environment: sdk.toolEnvironment, input: nil, timeout: timeout)
            if lastResult.succeeded {
                return
            }
            _ = try lastResult.requireSuccess()
        } else {
            _ = try result.requireSuccess()
        }
    }

    public func availableDataBytes(serial: String) throws -> Int64 {
        let output = try shell(serial: serial, command: "df -k /data")
        let lines = output.split(whereSeparator: \.isNewline).map(String.init)
        guard lines.count >= 2 else {
            throw MOSError.invalidArgument("Unable to read /data storage from device.")
        }

        let columns = lines[1].split(whereSeparator: \.isWhitespace).map(String.init)
        guard columns.count >= 4, let availableKB = Int64(columns[3]) else {
            throw MOSError.invalidArgument("Unable to parse /data storage: \(lines[1])")
        }
        return availableKB * 1024
    }

    public func screenSize(serial: String) throws -> (width: Int, height: Int) {
        let output = try shell(serial: serial, command: "wm size")
        guard let match = output.range(of: #"(\d+)x(\d+)"#, options: .regularExpression) else {
            throw MOSError.invalidArgument("Unable to parse screen size: \(output)")
        }
        let parts = output[match].split(separator: "x").compactMap { Int($0) }
        guard parts.count == 2 else {
            throw MOSError.invalidArgument("Unable to parse screen size: \(output)")
        }
        return (parts[0], parts[1])
    }

    public func foregroundPackage(serial: String) throws -> String? {
        let commands = [
            "dumpsys window | grep -E 'mCurrentFocus|mFocusedApp' | head -1",
            "dumpsys activity activities | grep -E 'mResumedActivity|topResumedActivity' | head -1",
            "dumpsys activity top | grep ACTIVITY | head -1"
        ]

        for command in commands {
            let output = try shell(serial: serial, command: command)
            if let packageName = Self.extractPackageName(fromFocusLine: output) {
                return packageName
            }
        }
        return nil
    }

    public func setDisplay(serial: String, width: Int, height: Int, dpi: Int, rotation: Int) throws {
        let normalizedRotation = ((rotation % 4) + 4) % 4
        let landscape = width > height

        _ = try? shell(serial: serial, command: "settings put system accelerometer_rotation 0")
        _ = try? shell(serial: serial, command: "settings put system user_rotation \(normalizedRotation)")
        _ = try? shell(serial: serial, command: "settings put secure show_rotation_suggestions 0")
        _ = try? shell(serial: serial, command: "cmd display set-user-rotation lock \(normalizedRotation)")

        try rotateHardware(serial: serial, landscape: landscape)
        _ = try shell(serial: serial, command: "wm size \(width)x\(height)")
        _ = try shell(serial: serial, command: "wm density \(dpi)")
    }

    public func androidVersion(serial: String) throws -> String {
        let release = try shell(serial: serial, command: "getprop ro.build.version.release")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let sdkVersion = try shell(serial: serial, command: "getprop ro.build.version.sdk")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return sdkVersion.isEmpty ? release : "Android \(release) / API \(sdkVersion)"
    }

    private func rotateHardware(serial: String, landscape: Bool) throws {
        for _ in 0..<4 {
            let frame = try displayFrame(serial: serial)
            if (landscape && frame.width > frame.height) || (!landscape && frame.height > frame.width) {
                return
            }
            try emulatorRotate(serial: serial)
            Thread.sleep(forTimeInterval: 0.8)
        }
    }

    private func displayFrame(serial: String) throws -> (width: Int, height: Int) {
        let output = try shell(serial: serial, command: "dumpsys window displays | grep 'DisplayFrames w=' | head -1")
        let pattern = #"DisplayFrames w=(\d+) h=(\d+)"#
        guard let match = output.range(of: pattern, options: .regularExpression) else {
            let size = try screenSize(serial: serial)
            return (size.width, size.height)
        }

        let value = String(output[match])
        let numbers = value.split { !$0.isNumber }.compactMap { Int($0) }
        guard numbers.count >= 2 else {
            let size = try screenSize(serial: serial)
            return (size.width, size.height)
        }
        return (numbers[0], numbers[1])
    }

    private func emulatorRotate(serial: String) throws {
        guard let adb = sdk.adb else {
            throw MOSError.toolNotFound("adb")
        }
        _ = try runner
            .run(
                adb,
                arguments: ["-s", serial, "emu", "rotate"],
                environment: sdk.toolEnvironment,
                input: nil,
                timeout: 20
            )
            .requireSuccess()
    }

    private static func extractPackageName(fromFocusLine output: String) -> String? {
        let tokens = output.split { character in
            character == " " ||
                character == "{" ||
                character == "}" ||
                character == "\n" ||
                character == "\t"
        }

        for token in tokens {
            guard let slash = token.firstIndex(of: "/") else {
                continue
            }
            let packageName = token[..<slash]
                .trimmingCharacters(in: CharacterSet(charactersIn: "[](),"))
            if packageName.contains(".") {
                return packageName
            }
        }
        return nil
    }

    public func inputTap(serial: String, x: Int, y: Int) throws {
        _ = try shell(serial: serial, command: "input tap \(x) \(y)")
    }

    public func inputSwipe(serial: String, x1: Int, y1: Int, x2: Int, y2: Int, durationMS: Int) throws {
        _ = try shell(serial: serial, command: "input swipe \(x1) \(y1) \(x2) \(y2) \(durationMS)")
    }

    public func playMacro(serial: String, script: MacroScript, repeatCount: Int = 1, speed: Double = 1.0) throws {
        let repeats = max(1, repeatCount)
        let normalizedSpeed = max(0.1, speed)
        for _ in 0..<repeats {
            for step in script.steps {
                switch step.kind {
                case .tap:
                    try inputTap(serial: serial, x: step.x, y: step.y)
                case .swipe:
                    try inputSwipe(
                        serial: serial,
                        x1: step.x,
                        y1: step.y,
                        x2: step.x2 ?? step.x,
                        y2: step.y2 ?? step.y,
                        durationMS: step.durationMS
                    )
                case .wait:
                    break
                }
                let delay = Double(max(0, step.delayAfterMS)) / 1000.0 / normalizedSpeed
                if delay > 0 {
                    Thread.sleep(forTimeInterval: delay)
                }
            }
        }
    }

    public func captureScreenshot(serial: String, to localURL: URL) throws {
        guard let adb = sdk.adb else {
            throw MOSError.toolNotFound("adb")
        }

        let remotePath = "/sdcard/macos_macro_screen.png"
        _ = try runner
            .run(
                adb,
                arguments: ["-s", serial, "shell", "screencap -p \(remotePath)"],
                environment: sdk.toolEnvironment,
                input: nil,
                timeout: 30
            )
            .requireSuccess()
        _ = try runner
            .run(
                adb,
                arguments: ["-s", serial, "pull", remotePath, localURL.path],
                environment: sdk.toolEnvironment,
                input: nil,
                timeout: 30
            )
            .requireSuccess()
    }

    public func uninstall(serial: String, packageName: String) throws {
        guard let adb = sdk.adb else {
            throw MOSError.toolNotFound("adb")
        }
        _ = try runner
            .run(
                adb,
                arguments: ["-s", serial, "uninstall", packageName],
                environment: sdk.toolEnvironment,
                input: nil,
                timeout: 120
            )
            .requireSuccess()
    }

    public func shell(serial: String, command: String) throws -> String {
        guard let adb = sdk.adb else {
            throw MOSError.toolNotFound("adb")
        }
        let result = try runner
            .run(
                adb,
                arguments: ["-s", serial, "shell", command],
                environment: sdk.toolEnvironment,
                input: nil,
                timeout: 60
            )
            .requireSuccess()
        return result.stdout
    }

    public func killEmulator(serial: String) throws {
        guard let adb = sdk.adb else {
            throw MOSError.toolNotFound("adb")
        }
        _ = try runner
            .run(
                adb,
                arguments: ["-s", serial, "emu", "kill"],
                environment: sdk.toolEnvironment,
                input: nil,
                timeout: 20
            )
            .requireSuccess()
    }

    public func root(serial: String) throws {
        guard let adb = sdk.adb else {
            throw MOSError.toolNotFound("adb")
        }
        _ = try runner
            .run(adb, arguments: ["-s", serial, "root"], environment: sdk.toolEnvironment, input: nil, timeout: 30)
            .requireSuccess()
    }

    public func remount(serial: String) throws {
        guard let adb = sdk.adb else {
            throw MOSError.toolNotFound("adb")
        }
        _ = try runner
            .run(adb, arguments: ["-s", serial, "remount"], environment: sdk.toolEnvironment, input: nil, timeout: 60)
            .requireSuccess()
    }

    public func applyVirtualIdentity(serial: String, configuration: InstanceConfiguration) throws {
        _ = try? shell(serial: serial, command: "settings put secure android_id \(configuration.identity.androidId)")
        for key in configuration.launchProperties.keys.sorted() {
            if key.hasPrefix("ro.") {
                continue
            }
            guard let value = configuration.launchProperties[key] else {
                continue
            }
            _ = try? shell(serial: serial, command: "setprop \(key) '\(Self.shellEscaped(value))'")
        }
    }

    public func applyGuestSystemSettings(serial: String, configuration: InstanceConfiguration) throws {
        let settings = configuration.resolvedSystemSettings
        if !settings.localeIdentifier.isEmpty {
            _ = try? shell(serial: serial, command: "setprop persist.sys.locale \(settings.localeIdentifier)")
            _ = try? shell(serial: serial, command: "settings put system system_locales \(settings.localeIdentifier)")
        }

        if settings.accessibilityEnabled {
            _ = try? shell(serial: serial, command: "settings put secure accessibility_enabled 1")
            if !settings.accessibilityService.isEmpty {
                _ = try? shell(
                    serial: serial,
                    command: "settings put secure enabled_accessibility_services '\(Self.shellEscaped(settings.accessibilityService))'"
                )
            }
        }

        if settings.batteryOptimizationDisabled {
            _ = try? shell(serial: serial, command: "dumpsys deviceidle disable")
            _ = try? shell(serial: serial, command: "settings put global low_power 0")
            _ = try? shell(serial: serial, command: "cmd appops set android RUN_ANY_IN_BACKGROUND allow")
        }

        if settings.stayAwakeWhileCharging {
            _ = try? shell(serial: serial, command: "settings put global stay_on_while_plugged_in 3")
        }

        try stabilizeNetwork(serial: serial)
    }

    public func stabilizeNetwork(serial: String) throws {
        _ = try? shell(serial: serial, command: "settings put global airplane_mode_on 0")
        _ = try? shell(serial: serial, command: "am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false")
        _ = try? shell(serial: serial, command: "svc wifi enable")
        _ = try? shell(serial: serial, command: "svc data enable")
    }

    public func openAccessibilitySettings(serial: String) throws {
        _ = try shell(serial: serial, command: "am start -a android.settings.ACCESSIBILITY_SETTINGS")
    }

    public func openAndroidSettings(serial: String) throws {
        _ = try shell(serial: serial, command: "am start -a android.settings.SETTINGS")
    }

    public func openLanguageSettings(serial: String) throws {
        _ = try shell(serial: serial, command: "am start -a android.settings.LOCALE_SETTINGS")
    }

    public func openBatteryOptimizationSettings(serial: String) throws {
        _ = try shell(serial: serial, command: "am start -a android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS")
    }

    private static func shellEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "'\\''")
    }

    public static func parseDevices(_ output: String) -> [AndroidDevice] {
        output
            .split(whereSeparator: \.isNewline)
            .dropFirst()
            .compactMap { rawLine in
                let line = String(rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty else {
                    return nil
                }

                let parts = line.split(separator: " ").map(String.init)
                guard parts.count >= 2 else {
                    return nil
                }

                let serial = parts[0]
                let state = AndroidDeviceState(rawValue: parts[1]) ?? .unknown
                var metadata: [String: String] = [:]

                for part in parts.dropFirst(2) {
                    let pair = part.split(separator: ":", maxSplits: 1).map(String.init)
                    if pair.count == 2 {
                        metadata[pair[0]] = pair[1]
                    }
                }

                return AndroidDevice(
                    serial: serial,
                    state: state,
                    model: metadata["model"],
                    product: metadata["product"],
                    transportID: metadata["transport_id"]
                )
            }
    }
}
