import Foundation

enum BoardSize: String, CaseIterable, Codable {
    case small
    case medium
    case large

    static let topBarHeight: CGFloat = 48

    var boardSide: CGFloat {
        switch self {
        case .small:
            320
        case .medium:
            520
        case .large:
            700
        }
    }

    var windowHeight: CGFloat {
        boardSide + Self.topBarHeight
    }

    var next: BoardSize {
        switch self {
        case .small:
            .medium
        case .medium:
            .large
        case .large:
            .small
        }
    }

    var buttonTitle: String {
        switch self {
        case .small:
            "Small"
        case .medium:
            "Medium"
        case .large:
            "Large"
        }
    }

    var accessibilityValue: String {
        rawValue
    }
}
