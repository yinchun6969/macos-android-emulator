import Foundation

public struct AndroidDeviceSpec: Identifiable, Sendable, Hashable, Codable {
    public var id: String { "\(brand)|\(modelName)" }

    public let brand: String
    public let manufacturer: String
    public let modelName: String
    public let modelCode: String
    public let marketName: String
    public let productName: String
    public let deviceName: String
    public let gpuHigh: String
    public let gpuBalanced: String
    public let virtualTACPrefixes: [String]

    public init(
        brand: String,
        manufacturer: String,
        modelName: String,
        modelCode: String,
        marketName: String,
        productName: String,
        deviceName: String,
        gpuHigh: String,
        gpuBalanced: String,
        virtualTACPrefixes: [String]
    ) {
        self.brand = brand
        self.manufacturer = manufacturer
        self.modelName = modelName
        self.modelCode = modelCode
        self.marketName = marketName
        self.productName = productName
        self.deviceName = deviceName
        self.gpuHigh = gpuHigh
        self.gpuBalanced = gpuBalanced
        self.virtualTACPrefixes = virtualTACPrefixes
    }
}

public enum DeviceCatalog {
    public static let specs: [AndroidDeviceSpec] = [
        AndroidDeviceSpec(
            brand: "HUAWEI",
            manufacturer: "HUAWEI",
            modelName: "nova 11",
            modelCode: "FOA-AL00",
            marketName: "HUAWEI nova 11",
            productName: "nova11",
            deviceName: "FOA",
            gpuHigh: "Adreno (TM) 740",
            gpuBalanced: "Adreno (TM) 730",
            virtualTACPrefixes: ["99001010", "99001011"]
        ),
        AndroidDeviceSpec(
            brand: "HUAWEI",
            manufacturer: "HUAWEI",
            modelName: "Pura 70 Pro",
            modelCode: "HBN-AL00",
            marketName: "HUAWEI Pura 70 Pro",
            productName: "pura70pro",
            deviceName: "HBN",
            gpuHigh: "Maleoon 910",
            gpuBalanced: "Maleoon 910",
            virtualTACPrefixes: ["99001020", "99001021"]
        ),
        AndroidDeviceSpec(
            brand: "SAMSUNG",
            manufacturer: "samsung",
            modelName: "Galaxy S24 Ultra",
            modelCode: "SM-S9280",
            marketName: "Samsung Galaxy S24 Ultra",
            productName: "e3q",
            deviceName: "e3q",
            gpuHigh: "Adreno (TM) 750",
            gpuBalanced: "Adreno (TM) 740",
            virtualTACPrefixes: ["99002010", "99002011"]
        ),
        AndroidDeviceSpec(
            brand: "SAMSUNG",
            manufacturer: "samsung",
            modelName: "Galaxy S23 Ultra",
            modelCode: "SM-S9180",
            marketName: "Samsung Galaxy S23 Ultra",
            productName: "dm3q",
            deviceName: "dm3q",
            gpuHigh: "Adreno (TM) 740",
            gpuBalanced: "Adreno (TM) 730",
            virtualTACPrefixes: ["99002020", "99002021"]
        ),
        AndroidDeviceSpec(
            brand: "Google",
            manufacturer: "Google",
            modelName: "Pixel 8 Pro",
            modelCode: "GC3VE",
            marketName: "Google Pixel 8 Pro",
            productName: "husky",
            deviceName: "husky",
            gpuHigh: "Mali-G715",
            gpuBalanced: "Mali-G710",
            virtualTACPrefixes: ["99003010", "99003011"]
        ),
        AndroidDeviceSpec(
            brand: "Google",
            manufacturer: "Google",
            modelName: "Pixel 7",
            modelCode: "GVU6C",
            marketName: "Google Pixel 7",
            productName: "panther",
            deviceName: "panther",
            gpuHigh: "Mali-G710",
            gpuBalanced: "Mali-G710",
            virtualTACPrefixes: ["99003020", "99003021"]
        ),
        AndroidDeviceSpec(
            brand: "Xiaomi",
            manufacturer: "Xiaomi",
            modelName: "Xiaomi 14",
            modelCode: "23127PN0CC",
            marketName: "Xiaomi 14",
            productName: "houji",
            deviceName: "houji",
            gpuHigh: "Adreno (TM) 750",
            gpuBalanced: "Adreno (TM) 740",
            virtualTACPrefixes: ["99004010", "99004011"]
        ),
        AndroidDeviceSpec(
            brand: "Redmi",
            manufacturer: "Xiaomi",
            modelName: "Redmi Note 13 Pro+",
            modelCode: "23090RA98C",
            marketName: "Redmi Note 13 Pro+",
            productName: "zircon",
            deviceName: "zircon",
            gpuHigh: "Mali-G610",
            gpuBalanced: "Mali-G610",
            virtualTACPrefixes: ["99004020", "99004021"]
        ),
        AndroidDeviceSpec(
            brand: "OPPO",
            manufacturer: "OPPO",
            modelName: "Find X7 Ultra",
            modelCode: "PHY110",
            marketName: "OPPO Find X7 Ultra",
            productName: "findx7ultra",
            deviceName: "PHY110",
            gpuHigh: "Adreno (TM) 750",
            gpuBalanced: "Adreno (TM) 740",
            virtualTACPrefixes: ["99005010", "99005011"]
        ),
        AndroidDeviceSpec(
            brand: "vivo",
            manufacturer: "vivo",
            modelName: "X100 Pro",
            modelCode: "V2324A",
            marketName: "vivo X100 Pro",
            productName: "x100pro",
            deviceName: "V2324A",
            gpuHigh: "Immortalis-G720",
            gpuBalanced: "Mali-G715",
            virtualTACPrefixes: ["99006010", "99006011"]
        ),
        AndroidDeviceSpec(
            brand: "OnePlus",
            manufacturer: "OnePlus",
            modelName: "OnePlus 12",
            modelCode: "PJD110",
            marketName: "OnePlus 12",
            productName: "OP594DL1",
            deviceName: "PJD110",
            gpuHigh: "Adreno (TM) 750",
            gpuBalanced: "Adreno (TM) 740",
            virtualTACPrefixes: ["99007010", "99007011"]
        ),
        AndroidDeviceSpec(
            brand: "HONOR",
            manufacturer: "HONOR",
            modelName: "Magic6 Pro",
            modelCode: "BVL-AN16",
            marketName: "HONOR Magic6 Pro",
            productName: "magic6pro",
            deviceName: "BVL",
            gpuHigh: "Adreno (TM) 750",
            gpuBalanced: "Adreno (TM) 740",
            virtualTACPrefixes: ["99008010", "99008011"]
        )
    ]

    public static var defaultSpec: AndroidDeviceSpec {
        specs[0]
    }

    public static var brands: [String] {
        Array(Set(specs.map(\.brand))).sorted()
    }

    public static func models(for brand: String) -> [AndroidDeviceSpec] {
        specs
            .filter { $0.brand.caseInsensitiveCompare(brand) == .orderedSame }
            .sorted { $0.modelName < $1.modelName }
    }

    public static func resolve(brand: String?, modelName: String?) -> AndroidDeviceSpec? {
        guard let brand, let modelName else {
            return nil
        }
        return specs.first {
            $0.brand.caseInsensitiveCompare(brand) == .orderedSame &&
            $0.modelName.caseInsensitiveCompare(modelName) == .orderedSame
        }
    }

    public static func randomSpec() -> AndroidDeviceSpec {
        specs.randomElement() ?? defaultSpec
    }
}
