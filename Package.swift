// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Hemosight",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Hemosight",
            targets: ["Hemosight"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Hemosight",
            path: "Hemosight",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "HemosightTests",
            dependencies: ["Hemosight"],
            path: "Tests/HemosightTests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
