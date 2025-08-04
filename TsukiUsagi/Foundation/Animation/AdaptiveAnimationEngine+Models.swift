import Foundation

// MARK: - 🎨 Animation Quality Models
extension AdaptiveAnimationEngine {

    /// アニメーション品質レベル
    enum AnimationQuality: CaseIterable {
        case ultra, high, medium, low, minimal

        var starCount: Int {
            switch self {
            case .ultra: return 80
            case .high: return 50
            case .medium: return 30
            case .low: return 15
            case .minimal: return 8
            }
        }

        var sparkleInterval: TimeInterval {
            switch self {
            case .ultra: return 0.1
            case .high: return 0.15
            case .medium: return 0.25
            case .low: return 0.4
            case .minimal: return 0.8
            }
        }

        var usesGPUAcceleration: Bool {
            switch self {
            case .ultra, .high, .medium: return true
            case .low, .minimal: return false
            }
        }

        var enablesComplexAnimations: Bool {
            switch self {
            case .ultra, .high: return true
            case .medium, .low, .minimal: return false
            }
        }
    }

    /// メモリプレッシャーレベル
    enum MemoryPressureLevel {
        case normal, warning, critical
    }
}
