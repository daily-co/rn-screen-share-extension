// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReactNativeDailyJSScreenShareExtension",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "ReactNativeDailyJSScreenShareExtension",
            targets: [
                "ReactNativeDailyJSScreenShareExtension"
            ]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "ReactNativeDailyJSScreenShareExtension",
            url: "https://www.daily.co/sdk/ReactNativeDailyJSScreenShareExtension.xcframework-0.0.1.zip",
            // path: "./dist/ReactNativeDailyJSScreenShareExtension.xcframework.zip"
        )
    ]
)
