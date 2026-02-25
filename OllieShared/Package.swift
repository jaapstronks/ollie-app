// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OllieShared",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v13)  // For command-line builds
    ],
    products: [
        .library(name: "OllieShared", targets: ["OllieShared"])
    ],
    targets: [
        .target(name: "OllieShared"),
        .testTarget(name: "OllieSharedTests", dependencies: ["OllieShared"])
    ]
)
