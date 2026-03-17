// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OtisShared",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)  // For CKSyncEngine support
    ],
    products: [
        .library(name: "OtisShared", targets: ["OtisShared"])
    ],
    targets: [
        .target(name: "OtisShared"),
        .testTarget(name: "OtisSharedTests", dependencies: ["OtisShared"])
    ]
)
