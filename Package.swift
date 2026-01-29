// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacTools",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MacTools", targets: ["MacTools"])
    ],
    targets: [
        .executableTarget(
            name: "MacTools",
            path: "Sources/MacTools",
            resources: [.process("Resources")],
            linkerSettings: [
                .linkedFramework("CoreWLAN"),
                .linkedFramework("IOKit")
            ]
        )
    ]
)
