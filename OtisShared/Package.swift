// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OtisShared",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v13)  // For command-line builds
    ],
    products: [
        .library(name: "OtisShared", targets: ["OtisShared"])
    ],
    targets: [
        .target(name: "OtisShared"),
        .testTarget(name: "OtisSharedTests", dependencies: ["OtisShared"])
    ]
)
