// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Turbo",
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
