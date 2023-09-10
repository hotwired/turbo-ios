// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Turbo",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "Turbo",
            targets: ["Turbo"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/quick/quick", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/quick/nimble", .upToNextMajor(from: "10.0.0")),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", .upToNextMajor(from: "9.0.0"))
    ],
    targets: [
        .target(
            name: "Turbo",
            dependencies: [],
            path: "Source",
            exclude: ["Info.plist"],
            resources: [
                .copy("WebView/turbo.js")
            ]
        ),
        .testTarget(
            name: "TurboTests",
            dependencies: [
                "Turbo",
                .product(name: "Quick", package: "quick"),
                .product(name: "Nimble", package: "nimble"),
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
            ],
            path: "Tests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
