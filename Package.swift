// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "StillgridSudoku",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "StillgridSudoku", targets: ["StillgridSudoku"])
    ],
    targets: [
        .executableTarget(
            name: "StillgridSudoku",
            path: "Sources/StillgridSudoku"
        )
    ]
)
