// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Turbo",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Turbo",
            targets: ["Turbo"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Turbo",
            dependencies: [],
            path: "Source",
            exclude: ["Info.plist"],
            resources: [
                .copy("WebView/turbo.js")
            ])
    ]
)
