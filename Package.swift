// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

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
        
    ],
    targets: [
        .target(
            name: "Reducer",
            dependencies: [
            
            ]
        ),
        .testTarget(
            name: "ReducerTests",
            dependencies: [
                "Reducer"
            ]
        ),
    ]
)
