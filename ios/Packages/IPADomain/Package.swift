// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IPADomain",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "IPADomain", targets: ["IPADomain"])],
    targets: [
        .target(name: "IPADomain", swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "IPADomainTests", dependencies: ["IPADomain"]),
    ]
)
