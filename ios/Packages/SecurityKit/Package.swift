// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SecurityKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SecurityKit", targets: ["SecurityKit"])],
    targets: [
        .target(name: "SecurityKit", swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "SecurityKitTests", dependencies: ["SecurityKit"]),
    ]
)
