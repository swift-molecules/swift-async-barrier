// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-async-barrier",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Async Barrier", targets: ["Async Barrier"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-async.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-async-waiter.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Async Barrier",
            dependencies: [
                .product(name: "Async Lifecycle", package: "swift-async"),
                .product(name: "Async Mutex", package: "swift-async"),
                .product(name: "Async Primitive", package: "swift-async"),
                .product(name: "Async Waiter", package: "swift-async-waiter"),
            ],
            path: "Sources/Async Barrier"
        ),
        .testTarget(
            name: "Async Barrier Tests",
            dependencies: [
                .product(name: "Async", package: "swift-async"),
                .target(name: "Async Barrier"),
            ],
            path: "Tests/Async Barrier Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = [
        .enableExperimentalFeature("RawLayout")
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
