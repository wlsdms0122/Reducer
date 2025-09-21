// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Reducer",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "Reducer",
            targets: ["Reducer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "509.0.0"..<"603.0.0")
    ],
    targets: [
        .macro(
            name: "ReducerMacro",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "Reducer",
            dependencies: [
                "ReducerMacro"
            ]
        ),
        .testTarget(
            name: "ReducerTests",
            dependencies: [
                "Reducer"
            ]
        ),
        .testTarget(
            name: "ReducerMacroTests",
            dependencies: [
                "ReducerMacro",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        )
    ]
)
