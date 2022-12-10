// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "NVHTarGzip",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .macOS(.v10_13),
    ],
    products: [
        .library(
            name: "NVHTarGzip", targets: ["NVHTarGzip"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "NVHTarGzip",
                path: "Classes",
                publicHeadersPath: ""),
    ]
)
    
