import Foundation
import MOSCore

enum SelfTestError: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        throw SelfTestError.failed(message)
    }
}

func testParseADBDevices() throws {
    let output = """
    List of devices attached
    emulator-5554 device product:sdk_gphone64_arm64 model:sdk_gphone64_arm64 transport_id:1
    emulator-5556 offline transport_id:2

    """

    let devices = ADBManager.parseDevices(output)

    try expect(devices.count == 2, "Expected 2 adb devices.")
    try expect(devices[0].serial == "emulator-5554", "Unexpected first serial.")
    try expect(devices[0].state == .device, "Unexpected first state.")
    try expect(devices[0].model == "sdk_gphone64_arm64", "Unexpected model.")
    try expect(devices[1].state == .offline, "Unexpected second state.")
}

func testParseInstalledSystemImages() throws {
    let output = """
    Path                                        | Version | Description
    system-images;android-35;google_apis;arm64-v8a | 9       | Google APIs ARM 64
    platform-tools                              | 36.0.0  | Android SDK Platform-Tools
    """

    try expect(
        AVDManager.parseInstalledSystemImages(output) == ["system-images;android-35;google_apis;arm64-v8a"],
        "System image parsing failed."
    )
}

func testCandidateRootsPreferEnvironment() throws {
    let roots = AndroidSDKLocator.candidateRoots(
        environment: ["ANDROID_HOME": "/tmp/android-home", "ANDROID_SDK_ROOT": "/tmp/android-root"],
        homeDirectory: "/Users/tester"
    )

    try expect(
        roots.map(\.path) == [
            "/tmp/android-home",
            "/tmp/android-root",
            "/Users/tester/Library/Android/sdk"
        ],
        "Candidate root ordering failed."
    )
}

func testResourcePlanner() throws {
    let plan = ResourcePlanner.plan(
        requestedInstances: 4,
        profile: .lean,
        physicalMemoryMB: 16_384
    )

    try expect(plan.recommendedMaxInstances == 5, "Lean profile capacity calculation failed.")
    try expect(plan.fitsRecommendedBudget, "Expected 4 lean instances to fit 16 GB host budget.")
    try expect(plan.perInstanceEstimatedHostMB == 2_304, "Unexpected per-instance memory estimate.")
}

func testInstanceNaming() throws {
    try expect(
        InstanceNaming.names(prefix: "mos phone", count: 3) == ["mos_phone_01", "mos_phone_02", "mos_phone_03"],
        "Instance pool naming failed."
    )
}

func testLaunchArguments() throws {
    let configuration = InstanceConfiguration.makeDefault(
        avdName: "macos_phone_01",
        deviceSpec: DeviceCatalog.defaultSpec,
        display: DisplayProfile(name: "1280 x 720 240 DPI", category: .tablet, width: 1280, height: 720, dpi: 240, fps: 30),
        runtimeProfile: .lean,
        memoryMBOverride: 3072,
        coresOverride: 2,
        gpuModeOverride: "host",
        diskSizeMB: 4096,
        rootEnabled: true,
        adbEnabled: true
    )
    let options = LaunchOptions(
        configuration: configuration,
        headless: true,
        noSnapshotLoad: true,
        port: 5554
    )
    let arguments = EmulatorManager.launchArguments(avdName: "macos_phone_01", options: options)

    try expect(arguments.contains("-no-window"), "Expected headless launch flag.")
    try expect(arguments.contains("-no-metrics"), "Expected metrics opt-out flag.")
    try expect(arguments.contains("-no-snapshot-save"), "Expected snapshot-save suppression flag.")
    try expect(arguments.contains("-no-boot-anim"), "Expected boot animation suppression flag.")
    try expect(arguments.contains("-camera-back"), "Expected camera disable flag.")
    try expect(arguments.contains("3072"), "Expected per-instance memory override.")
    try expect(arguments.contains("host"), "Expected per-instance GPU override.")
    try expect(arguments.contains("5554"), "Expected explicit emulator port.")
    // partition-size is controlled by AVD config disk.dataPartition.size
    // disk size is set via AVD config disk.dataPartition.size
    try expect(arguments.contains("-dpi-device"), "Expected DPI flag.")
    try expect(arguments.contains("240"), "Expected configured DPI.")
    try expect(arguments.contains("-vsync-rate"), "Expected FPS flag.")
    try expect(arguments.contains("30"), "Expected configured FPS.")
    try expect(arguments.contains("-netdelay"), "Expected network delay override.")
    try expect(arguments.contains("none"), "Expected no network delay.")
    try expect(arguments.contains("-netspeed"), "Expected network speed override.")
    try expect(arguments.contains("full"), "Expected full network speed.")
    try expect(arguments.contains("-dns-server"), "Expected explicit DNS servers.")
    try expect(arguments.contains("-writable-system"), "Expected root writable-system flag.")
    try expect(arguments.contains("-android-serialno"), "Expected Android serial flag.")
    try expect(!arguments.contains("+86"), "Phone number should be passed as decimal digits only.")
}

func testVirtualIdentity() throws {
    let identity = VirtualIdentityGenerator.makeIdentity()
    try expect(VirtualIdentityGenerator.isValidIMEI(identity.imei), "Generated IMEI should pass Luhn validation.")
    try expect(identity.androidId.count == 16, "Android ID should be 16 hex characters.")
    try expect(identity.wifiMacAddress.hasPrefix("02:"), "Generated MAC should use a local address prefix.")
}

func testStorageLayout() throws {
    let home = StorageLayout.preferredAVDHome(
        environment: ["ANDROID_EMULATOR_HOME": "/tmp/macos-android"],
        homeDirectory: "/Users/tester"
    )
    try expect(home.path == "/tmp/macos-android/avd", "AVD home should derive from emulator home.")
}

do {
    try testParseADBDevices()
    try testParseInstalledSystemImages()
    try testCandidateRootsPreferEnvironment()
    try testResourcePlanner()
    try testInstanceNaming()
    try testLaunchArguments()
    try testVirtualIdentity()
    try testStorageLayout()
    print("OK: MOSCore parser self-tests passed.")
} catch {
    fputs("selftest failed: \(error)\n", stderr)
    exit(1)
}
