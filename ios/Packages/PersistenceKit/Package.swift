// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PersistenceKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "PersistenceKit", targets: ["PersistenceKit"])],
    dependencies: [.package(path: "../IPADomain")],
    targets: [
        .target(
            name: "PersistenceKit",
            dependencies: [.product(name: "IPADomain", package: "IPADomain")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(name: "PersistenceKitTests", dependencies: ["PersistenceKit"]),
    ]
)
