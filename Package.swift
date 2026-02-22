// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "ConsoleKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "ConsoleKit", targets: ["ConsoleKit"]),
        .executable(name: "replexample", targets: ["replexample"])
    ],
    targets: [
        .target(
            name: "ConsoleKit",
            dependencies: [],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .define("SWIFT_PACKAGE")
            ]
        ),
        .executableTarget(
            name: "replexample",
            dependencies: ["ConsoleKit"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .define("SWIFT_PACKAGE")
            ]
        ),
        .testTarget(
            name: "ConsoleKitTests",
            dependencies: ["ConsoleKit"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .define("SWIFT_PACKAGE")
            ]
        ),
    ]
)
