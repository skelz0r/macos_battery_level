// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "BatteryTime",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "BatteryTime",
            swiftSettings: [.unsafeFlags(["-warnings-as-errors"])]
        ),
        .testTarget(
            name: "BatteryTimeTests",
            dependencies: ["BatteryTime"],
            resources: [.copy("Fixtures")],
            swiftSettings: [.unsafeFlags(["-warnings-as-errors"])]
        ),
    ]
)
