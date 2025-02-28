// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "ZILFSwift",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ZILFSwift", targets: ["ZILFSwift"]),
        .library(name: "ZILFCore", targets: ["ZILFCore"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ZILFSwift",
            dependencies: ["ZILFCore"]
        ),
        .target(
            name: "ZILFCore"
        ),
        .testTarget(
            name: "ZILFCoreTests",
            dependencies: ["ZILFCore"]
        ),
        .testTarget(
            name: "ZILFSwiftTests",
            dependencies: ["ZILFSwift"]
        )
    ]
)
