// swift-tools-version: 6.0
// KarutaApp - 英単語カルタフラッシュカードゲーム

import PackageDescription

let package = Package(
    name: "KarutaApp",
    platforms: [
        .iOS(.v17)
    ],
    targets: [
        .executableTarget(
            name: "KarutaApp",
            resources: [
                .copy("Resources"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
