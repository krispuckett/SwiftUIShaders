// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftUIShaders",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "SwiftUIShaders", targets: ["SwiftUIShaders"]),
    ],
    targets: [
        // The .metal sources are compiled into the module's default.metallib and
        // loaded at runtime via `ShaderLibrary.bundle(.module)`.
        .target(name: "SwiftUIShaders"),
    ]
)
