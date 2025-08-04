import Foundation
import Combine

// MARK: - 🔍 Performance Monitoring & Animation Control
extension AdaptiveAnimationEngine {

    // MARK: - Setup Methods

    internal func setupPerformanceMonitoring() {
        // 5秒ごとにパフォーマンスをチェック
        performanceMonitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.evaluatePerformance()
        }
    }

    // MARK: - 📈 Performance Evaluation

    internal func evaluatePerformance() {
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

    // 🛠 修正：実際のメモリ使用量を取得するように変更
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info)) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024 * 1024) // GB単位
        } else {
            return 0
        }
    }

    // MARK: - 🎚 Quality Adjustment

    internal func degradeQuality(reason: String) {
        guard let currentIndex = AnimationQuality.allCases.firstIndex(of: animationQuality),
              currentIndex < AnimationQuality.allCases.count - 1 else { return }

        let newQuality = AnimationQuality.allCases[currentIndex + 1]
        updateAnimationQuality(to: newQuality, reason: reason)
    }

    internal func improveQuality(reason: String) {
        guard let currentIndex = AnimationQuality.allCases.firstIndex(of: animationQuality),
              currentIndex > 0 else { return }

        let newQuality = AnimationQuality.allCases[currentIndex - 1]
        updateAnimationQuality(to: newQuality, reason: reason)
    }

    internal func updateAnimationQuality(to newQuality: AnimationQuality, reason: String) {
        print("🎛 Animation Quality: \(animationQuality) → \(newQuality) (\(reason))")

        DispatchQueue.main.async {
            self.animationQuality = newQuality

            // 一時的に starCount の自動上書きを止める
            // self.starCount = newQuality.starCount
            // self.sparkleInterval = newQuality.sparkleInterval
        }
    }

    // MARK: - 🧠 Memory Management

    internal func updateMemoryPressure(usage: Double) {
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
}
