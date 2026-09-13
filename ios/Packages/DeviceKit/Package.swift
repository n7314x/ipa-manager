// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DeviceKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "DeviceKit", targets: ["DeviceKit"])],
    dependencies: [.package(path: "../IPADomain")],
    targets: [
        .target(
            name: "DeviceKit",
            dependencies: [.product(name: "IPADomain", package: "IPADomain")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(name: "DeviceKitTests", dependencies: ["DeviceKit"]),
    ]
)
