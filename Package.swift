// swift-tools-version: 6.0
import PackageDescription

// TODO(follow-up): adopt Swift 6 strict concurrency. Pinned to .v5 for now so
// the existing actor-isolated Process termination handler and NSWorkspace
// observers compile without protocol/Sendable churn. Tracked for a later pass.
let package = Package(
    name: "CaffeinateMenubar",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "CaffeinateMenubar",
            path: "Sources/CaffeinateMenubar",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "CaffeinateMenubarTests",
            dependencies: ["CaffeinateMenubar"],
            path: "Tests/CaffeinateMenubarTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
