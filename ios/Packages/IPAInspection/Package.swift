// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IPAInspection",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "IPAInspection", targets: ["IPAInspection"])],
    dependencies: [
        .package(path: "../IPADomain"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.20"),
    ],
    targets: [
        .target(
            name: "IPAInspection",
            dependencies: [
                .product(name: "IPADomain", package: "IPADomain"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ],
            linkerSettings: [
                .linkedFramework("ImageIO"),
                .linkedFramework("Security", .when(platforms: [.macOS])),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "IPAInspectionTests",
            dependencies: [
                "IPAInspection",
                .product(name: "IPADomain", package: "IPADomain"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ]
        ),
    ]
)
