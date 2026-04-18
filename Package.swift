// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "macSudoku",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "macSudoku", targets: ["macSudoku"])
    ],
    targets: [
        .executableTarget(
            name: "macSudoku",
            path: "Sources/macSudoku"
        )
    ]
)

