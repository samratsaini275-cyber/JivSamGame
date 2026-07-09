// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CloutEmpire",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "CloutEmpire",
            path: "Sources/CloutEmpire",
            resources: [
                .copy("Resources/Images"),
                .process("Resources/ATTRIBUTION.txt"),
            ]
        ),
        .testTarget(
            name: "CloutEmpireTests",
            dependencies: ["CloutEmpire"],
            path: "Tests/CloutEmpireTests"
        ),
    ]
)
