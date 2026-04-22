// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "QuietSudoku",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "QuietSudoku", targets: ["QuietSudoku"])
    ],
    targets: [
        .executableTarget(
            name: "QuietSudoku",
            path: "Sources/QuietSudoku"
        )
    ]
)
