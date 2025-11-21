// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "smith-cli",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "smith-cli",
            targets: ["SmithCLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Smith-Tools/smith-core", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/Smith-Tools/smith-validation", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "SmithCLI",
            dependencies: [
                .product(name: "SmithCore", package: "smith-core"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SmithValidation", package: "smith-validation"),
                .product(name: "MaxwellsTCARules", package: "smith-validation")
            ]
        ),
        .testTarget(
            name: "SmithCLITests",
            dependencies: ["SmithCLI"]
        ),
    ]
)