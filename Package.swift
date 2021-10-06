// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "enum-key-paths",
  products: [
    .library(
      name: "EnumKeyPaths",
      targets: ["EnumKeyPaths"]
    )
  ],
  targets: [
    .target(
      name: "EnumKeyPaths"
    ),
    .testTarget(
      name: "EnumKeyPathsTests",
      dependencies: ["EnumKeyPaths"]
    ),
  ]
)
