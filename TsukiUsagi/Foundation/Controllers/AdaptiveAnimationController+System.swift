import Foundation
import SwiftUI
import Combine

// MARK: - 🔋 System State Management
extension AdaptiveAnimationController {

    // MARK: - Setup System Observers

    internal func setupSystemObservers() {
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

    // MARK: - 🔋 Power Management

    internal func updatePowerModeStatus() {
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

    // MARK: - 🧠 Memory Warning Handling

    internal func handleMemoryWarning() {
        memoryPressure = .critical
        updateAnimationQuality(to: .low, reason: "Memory warning received")
    }

    // MARK: - 🎯 Scene Phase Management

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
}
