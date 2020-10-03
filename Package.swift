// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ConsoleKit",
    platforms: [.macOS(.v10_14)],
    products: [
        .library(name: "ConsoleKit", targets: ["ConsoleKit"]),
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
