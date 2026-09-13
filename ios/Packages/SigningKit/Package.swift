// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SigningKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SigningKit", targets: ["SigningKit"])],
    dependencies: [
        .package(path: "../IPADomain"),
        .package(path: "../SecurityKit"),
    ],
    targets: [
        .target(
            name: "SigningKit",
            dependencies: [
                .product(name: "IPADomain", package: "IPADomain"),
                .product(name: "SecurityKit", package: "SecurityKit"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(name: "SigningKitTests", dependencies: ["SigningKit"]),
    ]
)
