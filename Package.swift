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
        .library(
            name: "AsyncSequenceKitPublished",
            targets: ["AsyncSequenceKitPublished"]),
    ],
    targets: [
        .target(
            name: "AsyncSequenceKit",
            dependencies: [
                "AsyncSequenceKitTypeErasure",
                "AsyncSequenceKitSubject",
                "AsyncSequenceKitPublished",
            ]),

        .target(
            name: "AsyncSequenceKitTypeErasure",
            dependencies: []),
        .testTarget(
            name: "AsyncSequenceKitTypeErasureTests",
            dependencies: ["AsyncSequenceKitTypeErasure"]),

        .target(
            name: "AsyncSequenceKitSubject",
            dependencies: []),
        .testTarget(
            name: "AsyncSequenceKitSubjectTests",
            dependencies: ["AsyncSequenceKitSubject"]),

        .target(
            name: "AsyncSequenceKitPublished",
            dependencies: ["AsyncSequenceKitSubject"]),
        .testTarget(
            name: "AsyncSequenceKitPublishedTests",
            dependencies: ["AsyncSequenceKitPublished"]),
    ]
)
