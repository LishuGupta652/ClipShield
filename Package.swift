// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipShield",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ClipShield", targets: ["ClipShieldApp"]),
        .executable(name: "clipshield", targets: ["ClipShieldCLI"])
    ],
    targets: [
        .target(
            name: "ClipShieldCore",
            path: "Sources/ClipShieldCore",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "ClipShieldApp",
            dependencies: ["ClipShieldCore"],
            path: "Sources/ClipShieldApp"
        ),
        .executableTarget(
            name: "ClipShieldCLI",
            dependencies: ["ClipShieldCore"],
            path: "Sources/ClipShieldCLI"
        )
    ]
)
