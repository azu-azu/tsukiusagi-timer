import Combine
import SwiftUI

/// アニメーション関連の処理を担当するManager
final class TimerAnimationManager: ObservableObject {
    @Published var flashStars = false
    @Published var shouldSuppressAnimation = false
    @Published var shouldSuppressSessionFinishedAnimation = false

    // 🔔 START アニメ用トリガー
    let startPulse = PassthroughSubject<Void, Never>()

    // MARK: - Animation Methods

    /// diamondアニメーションとstartPulseアニメーションを発火
    func triggerStartAnimations() {
        if !shouldSuppressAnimation {
            flashStars.toggle()
            DispatchQueue.main.async {
                self.startPulse.send()
            }
        }
    }

    /// アニメーション抑制フラグをリセット
    func resetAnimationSuppression() {
        shouldSuppressAnimation = false
        shouldSuppressSessionFinishedAnimation = false
    }

    /// アニメーション抑制フラグを設定
    func suppressAnimations() {
        shouldSuppressAnimation = true
        shouldSuppressSessionFinishedAnimation = true
    }
}
