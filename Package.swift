// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "RheaTime",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v7),
        .macOS(.v10_15),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "RheaTime",
            targets: ["RheaTime"]),
        .library(
            name: "RheaTimeMacroExpansion",
            targets: ["RheaTimeMacroExpansion"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "601.0.1"..<"606.0.0"),
        .package(url: "https://github.com/reers/SectionReader.git", from: "1.0.0"),

    ],
    targets: [
        .target(
            name: "RheaTimeMacroExpansion",
            dependencies: [
                .product(name: "SwiftBasicFormat", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .macro(
            name: "RheaTimeMacros",
            dependencies: [
                "RheaTimeMacroExpansion",
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "RheaTime",
            dependencies: ["OCRhea", "RheaTimeMacros", "SectionReader"],
            path: "Sources/RheaTime",
            swiftSettings: []
        ),
        .target(name: "OCRhea"),
        .testTarget(
            name: "RheaTests",
            dependencies: [
                "RheaTime",
                "RheaTimeMacros",
                "RheaTimeMacroExpansion",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
