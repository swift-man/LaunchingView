// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LaunchingView",
    platforms: [
      .iOS(.v16),
      .macOS(.v13),
    ],
    products: [
        .library(
            name: "LaunchingView",
            targets: ["LaunchingView"]),
    ],
    dependencies: [
      .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.5"),
      .package(url: "https://github.com/swift-man/LaunchingService", from: "0.9.2"),
    ],
    targets: [
        .target(
            name: "LaunchingView",
            dependencies: [
              .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
              .product(name: "LaunchingService", package: "LaunchingService"),
            ]),
        .testTarget(
            name: "LaunchingViewTests",
            dependencies: ["LaunchingView"]),
    ]
)
