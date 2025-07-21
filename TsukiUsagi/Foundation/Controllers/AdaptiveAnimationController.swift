import SwiftUI
import Combine

// MARK: - 🎛 AdaptiveAnimationController
/// 動的にアニメーションのパフォーマンスを調整するコントローラー
class AdaptiveAnimationController: ObservableObject {

    // MARK: - 📊 Performance Metrics
    @Published var starCount: Int = 50
    @Published var sparkleInterval: TimeInterval = 0.15
    @Published var animationQuality: AnimationQuality = .high
    @Published var isLowPowerMode: Bool = false
    @Published var isBackgroundMode: Bool = false
    @Published var memoryPressure: MemoryPressureLevel = .normal

    // MARK: - 🎨 Animation Quality Levels
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

    // MARK: - 🧠 Memory Pressure Detection
    enum MemoryPressureLevel {
        case normal, warning, critical
    }

    // MARK: - ⚙️ Configuration
    private var cancellables = Set<AnyCancellable>()
    private var performanceMonitorTimer: Timer?

    init() {
        setupPerformanceMonitoring()
        setupSystemObservers()
    }

    deinit {
        performanceMonitorTimer?.invalidate()
    }

    // MARK: - 🔍 System Monitoring
    private func setupSystemObservers() {
        // Low Power Mode の監視
        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .sink { [weak self] _ in
                self?.updatePowerModeStatus()
            }
            .store(in: &cancellables)

        // Memory Warning の監視
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }

    private func setupPerformanceMonitoring() {
        // 5秒ごとにパフォーマンスをチェック
        performanceMonitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.evaluatePerformance()
        }
    }

    // MARK: - 📈 Performance Evaluation
    private func evaluatePerformance() {
		_ = getCurrentCPUUsage()
        let memoryUsage = getCurrentMemoryUsage()

        // 星が減ってしまうのでいったんコメントアウト
        // CPU使用率に基づく自動調整
        // if cpuUsage > 60 {
        //     degradeQuality(reason: "High CPU usage: \(cpuUsage)%")
        // } else if cpuUsage < 20 && animationQuality != .ultra {
        //     improveQuality(reason: "Low CPU usage: \(cpuUsage)%")
        // }

        // メモリ使用量に基づく調整
        updateMemoryPressure(usage: memoryUsage)
    }

    private func getCurrentCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                        task_flavor_t(MACH_TASK_BASIC_INFO),
                        $0,
                        &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024) // MB単位
        }
        return 0
    }

    private func getCurrentMemoryUsage() -> Double {
        let processInfo = ProcessInfo.processInfo
        return Double(processInfo.physicalMemory) / (1024 * 1024 * 1024) // GB単位
    }

    // MARK: - 🎚 Quality Adjustment
    private func degradeQuality(reason: String) {
        guard let currentIndex = AnimationQuality.allCases.firstIndex(of: animationQuality),
              currentIndex < AnimationQuality.allCases.count - 1 else { return }

        let newQuality = AnimationQuality.allCases[currentIndex + 1]
        updateAnimationQuality(to: newQuality, reason: reason)
    }

    private func improveQuality(reason: String) {
        guard let currentIndex = AnimationQuality.allCases.firstIndex(of: animationQuality),
              currentIndex > 0 else { return }

        let newQuality = AnimationQuality.allCases[currentIndex - 1]
        updateAnimationQuality(to: newQuality, reason: reason)
    }

    private func updateAnimationQuality(to newQuality: AnimationQuality, reason: String) {
        print("🎛 Animation Quality: \(animationQuality) → \(newQuality) (\(reason))")

        DispatchQueue.main.async {
            self.animationQuality = newQuality

            // 一時的に starCount の自動上書きを止める
            // self.starCount = newQuality.starCount
            // self.sparkleInterval = newQuality.sparkleInterval
        }
    }

    // MARK: - 🔋 Power Management
    private func updatePowerModeStatus() {
        let isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

        DispatchQueue.main.async {
            self.isLowPowerMode = isLowPower

            // 星が減ってしまうのでいったんコメントアウト
            // if isLowPower {
            //     self.updateAnimationQuality(to: .minimal, reason: "Low Power Mode enabled")
            // } else if self.animationQuality == .minimal {
            //     self.updateAnimationQuality(to: .medium, reason: "Low Power Mode disabled")
            // }
        }
    }

    // MARK: - 🧠 Memory Management
    private func handleMemoryWarning() {
        memoryPressure = .critical
        updateAnimationQuality(to: .low, reason: "Memory warning received")
    }

    private func updateMemoryPressure(usage: Double) {
        let newPressure: MemoryPressureLevel

        if usage > 4.0 {
            newPressure = .critical
        } else if usage > 2.0 {
            newPressure = .warning
        } else {
            newPressure = .normal
        }

        if newPressure != memoryPressure {
            DispatchQueue.main.async {
                self.memoryPressure = newPressure

                switch newPressure {
                case .critical:
                    self.updateAnimationQuality(to: .minimal, reason: "Critical memory pressure")
                case .warning:
                    self.updateAnimationQuality(to: .low, reason: "Memory pressure warning")
                case .normal:
                    if self.animationQuality == .minimal || self.animationQuality == .low {
                        self.updateAnimationQuality(to: .medium, reason: "Memory pressure normalized")
                    }
                }
            }
        }
    }

    // MARK: - 🎯 Scene Management
    func updateScenePhase(_ phase: ScenePhase) {
        DispatchQueue.main.async {
            switch phase {
            case .active:
                self.isBackgroundMode = false
                if self.animationQuality == .minimal && !self.isLowPowerMode {
                    self.updateAnimationQuality(to: .medium, reason: "App became active")
                }
            case .inactive, .background:
                self.isBackgroundMode = true
            @unknown default:
                break
            }
        }
    }

    // MARK: - 🎨 UI Helpers
    var shouldUseGPUAcceleration: Bool {
        animationQuality.usesGPUAcceleration && !isLowPowerMode
    }

    var shouldEnableComplexAnimations: Bool {
        animationQuality.enablesComplexAnimations && !isBackgroundMode && !isLowPowerMode
    }

    var effectiveStarCount: Int {
        // 星が減ってしまうのでいったんコメントアウト
        // if isBackgroundMode { return 0 }
        // if isLowPowerMode { return min(starCount, 8) }
        return starCount
    }

    var effectiveSparkleInterval: TimeInterval {
        if isBackgroundMode { return 10.0 } // ほぼ停止
        if isLowPowerMode { return sparkleInterval * 2 }
        return sparkleInterval
    }
}

// MARK: - 🎭 Adaptive Animation Views

struct AdaptiveFlowingStarsView: View {
    @StateObject private var controller = AdaptiveAnimationController()
    @Environment(\.scenePhase) private var scenePhase

    let baseStarCount: Int
    let angle: Angle
    let durationRange: ClosedRange<Double>
    let sizeRange: ClosedRange<CGFloat>
    let spawnArea: StarSpawnArea?

    var body: some View {
        Group {
            if !controller.isBackgroundMode && controller.effectiveStarCount > 0 {
                FlowingStarsView(
                    starCount: controller.effectiveStarCount,
                    angle: angle,
                    durationRange: durationRange,
                    sizeRange: sizeRange,
                    spawnArea: spawnArea
                )
                .conditionalDrawingGroup(controller.shouldUseGPUAcceleration)
                .transition(.opacity)
            } else {
                Color.clear
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            controller.updateScenePhase(newPhase)
        }
    }
}

struct AdaptiveSparkleStarsView: View {
    @StateObject private var controller = AdaptiveAnimationController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !controller.isBackgroundMode {
                SparkleStarsView()
                    .conditionalDrawingGroup(controller.shouldUseGPUAcceleration)
                    .transition(.opacity)
            } else {
                Color.clear
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            controller.updateScenePhase(newPhase)
        }
    }
}

struct AdaptiveMoonView: View {
    @StateObject private var controller = AdaptiveAnimationController()
    @Environment(\.scenePhase) private var scenePhase

    let moonSize: CGFloat
    let glitterText: String
    let size: CGSize

    var body: some View {
        MoonView(moonSize: moonSize, glitterText: glitterText, size: size)
            .conditionalDrawingGroup(controller.shouldUseGPUAcceleration)
            .onChange(of: scenePhase) { _, newPhase in
                controller.updateScenePhase(newPhase)
            }
    }
}

// MARK: - 🛠 Helper Extensions

extension View {
    @ViewBuilder
    func conditionalDrawingGroup(_ condition: Bool) -> some View {
        if condition {
            self.drawingGroup()
        } else {
            self
        }
    }
}

// MARK: - 📊 Performance Debug View (開発用)

struct PerformanceDebugView: View {
    @StateObject private var controller = AdaptiveAnimationController()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🎛 Performance Monitor")
                .font(.headline)

            Text("Quality: \(controller.animationQuality)")
            Text("Stars: \(controller.effectiveStarCount)")
            Text("Sparkle Interval: \(String(format: "%.2f", controller.effectiveSparkleInterval))s")
            Text("GPU Accel: \(controller.shouldUseGPUAcceleration ? "ON" : "OFF")")
            Text("Low Power: \(controller.isLowPowerMode ? "ON" : "OFF")")
            Text("Background: \(controller.isBackgroundMode ? "ON" : "OFF")")
            Text("Memory: \(controller.memoryPressure)")
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - 🚀 Usage Example

struct AdaptiveAnimationDemoView: View {
    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()

            // アダプティブアニメーション
            AdaptiveFlowingStarsView(
                baseStarCount: 50,
                angle: .degrees(90),
                durationRange: 24...40,
                sizeRange: 2...4,
                spawnArea: nil
            )

            AdaptiveSparkleStarsView()

            AdaptiveMoonView(
                moonSize: 200,
                glitterText: "✨",
                size: UIScreen.main.bounds.size
            )

            // デバッグ情報（開発時のみ）
            VStack {
                Spacer()
                HStack {
                    PerformanceDebugView()
                    Spacer()
                }
                .padding()
            }
        }
    }
}

#Preview {
    AdaptiveAnimationDemoView()
}
