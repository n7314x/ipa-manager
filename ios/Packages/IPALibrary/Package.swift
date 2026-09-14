// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IPALibrary",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "IPALibrary", targets: ["IPALibrary"])],
    dependencies: [
        .package(path: "../IPADomain"),
        .package(path: "../IPAInspection"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.20"),
    ],
    targets: [
        .target(
            name: "IPALibrary",
            dependencies: [
                .product(name: "IPADomain", package: "IPADomain"),
                .product(name: "IPAInspection", package: "IPAInspection"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "IPALibraryTests",
            dependencies: [
                "IPALibrary",
                .product(name: "IPADomain", package: "IPADomain"),
                .product(name: "IPAInspection", package: "IPAInspection"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ]
        ),
    ]
)
