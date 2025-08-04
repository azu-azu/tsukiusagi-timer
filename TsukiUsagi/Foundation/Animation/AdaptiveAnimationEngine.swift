import SwiftUI
import Combine

// MARK: - 🎛 AdaptiveAnimationEngine
/// 動的にアニメーションのパフォーマンスを調整するエンジン
class AdaptiveAnimationEngine: ObservableObject {

    // MARK: - 📊 Published Properties
    @Published var starCount: Int = 50
    @Published var sparkleInterval: TimeInterval = 0.15
    @Published var animationQuality: AnimationQuality = .high
    @Published var isLowPowerMode: Bool = false
    @Published var isBackgroundMode: Bool = false
    @Published var memoryPressure: MemoryPressureLevel = .normal

    // MARK: - ⚙️ Internal Properties
    internal var cancellables = Set<AnyCancellable>()
    internal var performanceMonitorTimer: Timer?

    // MARK: - 🏗 Initialization
    init() {
        setupPerformanceMonitoring()
        setupSystemObservers()
    }

    deinit {
        performanceMonitorTimer?.invalidate()
    }

    // MARK: - 🎯 Public API

    /// 現在の効果的な星の数を取得
    var effectiveStarCount: Int {
        return starCount
    }

    /// 現在の効果的なスパークル間隔を取得
    var effectiveSparkleInterval: TimeInterval {
        if isBackgroundMode { return 10.0 } // ほぼ停止
        if isLowPowerMode { return sparkleInterval * 2 }
        return sparkleInterval
    }

    /// GPU アクセラレーションを使用すべきかどうか
    var shouldUseGPUAcceleration: Bool {
        animationQuality.usesGPUAcceleration && !isLowPowerMode
    }

    /// 複雑なアニメーションを有効にすべきかどうか
    var shouldEnableComplexAnimations: Bool {
        animationQuality.enablesComplexAnimations && !isBackgroundMode && !isLowPowerMode
    }
}
