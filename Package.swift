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
        .target(
            name: "AsyncSequenceKit",
            dependencies: [
                "_AsyncSequenceKitTypeErasure",
                "_AsyncSequenceKitSubject",
            ]),

        .target(
            name: "_AsyncSequenceKitTypeErasure",
            dependencies: []),
        .testTarget(
            name: "_AsyncSequenceKitTypeErasureTests",
            dependencies: ["_AsyncSequenceKitTypeErasure"]),

        .target(
            name: "_AsyncSequenceKitSubject",
            dependencies: []),
        .testTarget(
            name: "_AsyncSequenceKitSubjectTests",
            dependencies: ["_AsyncSequenceKitSubject"]),
    ]
)
