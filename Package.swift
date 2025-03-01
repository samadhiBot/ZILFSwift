// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "ZILFSwift",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ZILFSwift", targets: ["ZILFSwift"]),
        .executable(name: "CloakOfDarkness", targets: ["CloakOfDarkness"]),
        .library(name: "ZILFCore", targets: ["ZILFCore"]),
        .library(name: "ZILFTestSupport", targets: ["ZILFTestSupport"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ZILFSwift",
            dependencies: ["ZILFCore"]
        ),
        .executableTarget(
            name: "CloakOfDarkness",
            dependencies: ["ZILFCore"]
        ),
        .target(
            name: "ZILFCore"
        ),
        .target(
            name: "ZILFTestSupport",
            dependencies: ["ZILFCore"],
            path: "Sources/ZILFTestSupport"
        ),
        .testTarget(
            name: "ZILFCoreTests",
            dependencies: ["ZILFCore", "ZILFTestSupport"]
        ),
        .testTarget(
            name: "ZILFSwiftTests",
            dependencies: ["ZILFSwift", "ZILFTestSupport"]
        )
    ]
)
