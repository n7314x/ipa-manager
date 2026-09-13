// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IPAInspection",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "IPAInspection", targets: ["IPAInspection"])],
    dependencies: [.package(path: "../IPADomain")],
    targets: [
        .target(
            name: "IPAInspection",
            dependencies: [.product(name: "IPADomain", package: "IPADomain")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(name: "IPAInspectionTests", dependencies: ["IPAInspection"]),
    ]
)
