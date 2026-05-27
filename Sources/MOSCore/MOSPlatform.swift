import Foundation

public final class MOSPlatform {
    public let sdk: AndroidSDK
    public let avdManager: AVDManager
    public let adbManager: ADBManager
    public let emulatorManager: EmulatorManager
    public let instancePoolManager: InstancePoolManager

    public init(sdk: AndroidSDK, runner: ProcessRunning = FoundationProcessRunner()) {
        try? StorageLayout.ensureInstanceDirectories()
        self.sdk = sdk
        self.avdManager = AVDManager(sdk: sdk, runner: runner)
        self.adbManager = ADBManager(sdk: sdk, runner: runner)
        self.emulatorManager = EmulatorManager(sdk: sdk, runner: runner)
        self.instancePoolManager = InstancePoolManager(
            avdManager: avdManager,
            emulatorManager: emulatorManager
        )
    }

    public static func discover() throws -> MOSPlatform {
        guard let sdk = AndroidSDKLocator.discover() else {
            throw MOSError.androidSDKNotFound
        }
        return MOSPlatform(sdk: sdk)
    }
}
