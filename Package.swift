// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MOSPlatform",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "MOSCore", targets: ["MOSCore"]),
        .executable(name: "mosctl", targets: ["mosctl"]),
        .executable(name: "mos-selftest", targets: ["MOSSelfTest"]),
        .executable(name: "MOSMacApp", targets: ["MOSMacApp"])
    ],
    targets: [
        .target(name: "MOSCore"),
        .executableTarget(
            name: "mosctl",
            dependencies: ["MOSCore"]
        ),
        .executableTarget(
            name: "MOSMacApp",
            dependencies: ["MOSCore"]
        ),
        .executableTarget(
            name: "MOSSelfTest",
            dependencies: ["MOSCore"]
        )
    ]
)
