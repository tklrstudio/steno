// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "steno",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "steno",
            dependencies: ["HotKey"],
            path: "Sources/steno",
            resources: [.process("Resources")]
        ),
    ]
)
