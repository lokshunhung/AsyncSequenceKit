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
        .library(
            name: "AsyncSequenceKitTypeErasure",
            targets: ["AsyncSequenceKitTypeErasure"]),
        .library(
            name: "AsyncSequenceKitSubject",
            targets: ["AsyncSequenceKitSubject"]),
    ],
    targets: [
        .target(
            name: "AsyncSequenceKit",
            dependencies: [
                "AsyncSequenceKitTypeErasure",
                "AsyncSequenceKitSubject",
            ]),
        .target(
            name: "AsyncSequenceKitPlatform", // <-- private
            dependencies: []),

        .target(
            name: "AsyncSequenceKitTypeErasure",
            dependencies: []),
        .testTarget(
            name: "AsyncSequenceKitTypeErasureTests",
            dependencies: ["AsyncSequenceKitTypeErasure"]),
        .testTarget(
            name: "AsyncSequenceKitTypeErasureTypeCheckingTests",
            dependencies: ["AsyncSequenceKitTypeErasure"]),

        .target(
            name: "AsyncSequenceKitSubject",
            dependencies: ["AsyncSequenceKitPlatform"]),
        .testTarget(
            name: "AsyncSequenceKitSubjectTests",
            dependencies: ["AsyncSequenceKitSubject"]),
    ]
)
