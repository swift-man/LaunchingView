// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LaunchingView",
    platforms: [
      .iOS(.v15),
      .macOS(.v12),
    ],
    products: [
        .library(
            name: "LaunchingView",
            targets: ["LaunchingView"]),
    ],
    dependencies: [
      .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.50.1"),
      .package(url: "https://github.com/swift-man/LaunchingService", branch: "feature/notice"),
    ],
    targets: [
        .target(
            name: "LaunchingView",
            dependencies: [
              .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
              .product(name: "LaunchingService", package: "LaunchingService"),
            ]),
    ]
)
