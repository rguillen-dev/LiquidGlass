// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiquidGlass",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LiquidGlass",
            targets: ["LiquidGlass"]
        )
    ],
    targets: [
        .target(
            name: "LiquidGlass",
            path: "Sources/LiquidGlass"
        ),
        .testTarget(
            name: "LiquidGlassTests",
            dependencies: ["LiquidGlass"],
            path: "Tests/LiquidGlassTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
