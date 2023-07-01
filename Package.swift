// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AsyncSequenceKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "AsyncSequenceKit",
            targets: ["AsyncSequenceKit"]),
    ],
    targets: [
        .executableTarget(
            name: "_Playground",
            dependencies: [
                "AsyncSequenceKit",
                "Producer",
            ]),

        .target(
            name: "AsyncSequenceKit",
            dependencies: []),
        .testTarget(
            name: "AsyncSequenceKitTests",
            dependencies: ["AsyncSequenceKit"]),

        .target(
            name: "Producer",
            dependencies: []),
    ]
)
