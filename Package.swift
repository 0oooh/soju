// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Soju",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "SojuKit"),
        .executableTarget(name: "Soju", dependencies: ["SojuKit"]),
        .testTarget(name: "SojuKitTests", dependencies: ["SojuKit"]),
    ]
)
