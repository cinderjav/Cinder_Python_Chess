// swift-tools-version:5.9
import PackageDescription

// Pure-Swift training logic (plan, interval engine, formatting, stats).
// It has no Apple-framework dependencies, so `swift test` runs on macOS and Linux.
let package = Package(
    name: "TrainingKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "TrainingKit", targets: ["TrainingKit"]),
    ],
    targets: [
        .target(name: "TrainingKit"),
        .testTarget(name: "TrainingKitTests", dependencies: ["TrainingKit"]),
    ]
)
