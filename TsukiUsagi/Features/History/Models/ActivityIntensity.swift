import SwiftUI

enum ActivityIntensity: String, Codable, CaseIterable {
    case none = "none"
    case low = "low"
    case medium = "medium"
    case high = "high"

    init(totalMinutes: Int) {
        switch totalMinutes {
        case 0: self = .none
        case 1...30: self = .low
        case 31...90: self = .medium
        default: self = .high
        }
    }

    var indicatorSize: CGFloat {
        switch self {
        case .none: return 6
        case .low: return 6
        case .medium: return 8
        case .high: return 10
        }
    }

    var color: Color {
        switch self {
        case .none: return DesignTokens.Calendar.noActivityColor
        case .low: return DesignTokens.Calendar.lowActivityColor
        case .medium: return DesignTokens.Calendar.mediumActivityColor
        case .high: return DesignTokens.Calendar.highActivityColor
        }
    }
}

// DesignTokens拡張も追加
extension DesignTokens {
    struct Calendar {
        static let cellSize: CGFloat = 40
        static let cellSpacing: CGFloat = 4
        static let weekdayHeight: CGFloat = 30
        static let detailViewMaxHeight: CGFloat = 200

        // 活動レベル色
        static let noActivityColor = Color.gray.opacity(0.3)
        static let lowActivityColor = Color.green.opacity(0.6)
        static let mediumActivityColor = Color.yellow.opacity(0.7)
        static let highActivityColor = Color.orange.opacity(0.8)
    }
}
