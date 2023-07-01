// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AsyncSequenceKit",
    products: [
        .library(
            name: "AsyncSequenceKit",
            targets: ["AsyncSequenceKit"]),
    ],
    targets: [
        .target(
            name: "AsyncSequenceKit",
            dependencies: []),
        .testTarget(
            name: "AsyncSequenceKitTests",
            dependencies: ["AsyncSequenceKit"]),
    ]
)
