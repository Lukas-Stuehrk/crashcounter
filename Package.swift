// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "crashcounter",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "crashcounter",
            dependencies: []),
    ]
)
