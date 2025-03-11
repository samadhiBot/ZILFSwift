// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "ZILFSwift",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "CloakOfDarkness", targets: ["CloakOfDarkness"]),
        .executable(name: "HelloWorldGame", targets: ["HelloWorldGame"]),
        .library(name: "ZILFCore", targets: ["ZILFCore"]),
        .library(name: "ZILFTestSupport", targets: ["ZILFTestSupport"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "CloakOfDarkness",
            dependencies: ["ZILFCore"]
        ),
        .executableTarget(
            name: "HelloWorldGame",
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
            dependencies: [
                "ZILFCore",
                "ZILFTestSupport"
            ]
        ),
        .testTarget(
            name: "GameTests",
            dependencies: [
                "CloakOfDarkness",
                "HelloWorldGame",
                "ZILFTestSupport",
            ]
        )
    ]
)
