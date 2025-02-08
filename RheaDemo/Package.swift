// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RheaDemo",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v7),
        .macOS(.v10_15),
        .visionOS(.v1)
    ],
    dependencies: [
        .package(name: "RheaTime", path: "../")
    ],
    targets: [
        .executableTarget(
            name: "RheaDemo",
            dependencies: [
                .product(name: "RheaTime", package: "RheaTime") // 正确指定产品依赖
            ],
            swiftSettings: [.enableExperimentalFeature("SymbolLinkageMarkers")]
        ),
    ]
)
