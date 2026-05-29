// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CaffeinateMenubar",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "CaffeinateMenubar",
            path: "Sources/CaffeinateMenubar"
        ),
        .testTarget(
            name: "CaffeinateMenubarTests",
            dependencies: ["CaffeinateMenubar"],
            path: "Tests/CaffeinateMenubarTests"
        ),
    ]
)
