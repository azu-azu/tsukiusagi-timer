//
//  TimerAnimationController.swift
//  TsukiUsagi
//
//  Created by Kazumi on 2025/01/01.
//

import Combine
import Foundation

/// タイマーアニメーション制御の実装クラス
/// 星の点滅、セッション完了アニメーション、ハプティックフィードバックを管理
@MainActor
final class TimerAnimationController: TimerAnimationControllerProtocol {

    // MARK: - Published Properties

    @Published var flashStars: Bool = false
    @Published var shouldSuppressAnimation: Bool = false
    @Published var shouldSuppressSessionFinishedAnimation: Bool = false

    let startPulse = PassthroughSubject<Void, Never>()

    // MARK: - Dependencies

    private let hapticService: HapticServiceable

    // MARK: - Initialization

    init(hapticService: HapticServiceable) {
        self.hapticService = hapticService
    }

    // MARK: - Public Methods

    /// スタートアニメーションを発火（星の点滅 + パルス）
    func triggerStartAnimations() {
        if !shouldSuppressAnimation {
            flashStars.toggle()
            DispatchQueue.main.async {
                self.startPulse.send()
            }
        }
    }

    /// セッション完了アニメーションを発火
    func triggerSessionFinishedAnimations() {
        if !shouldSuppressSessionFinishedAnimation {
            // セッション完了時のアニメーション処理
            // 現在のTimerViewModelでは具体的な実装がないため、
            // 将来的に拡張可能な形で実装
            flashStars.toggle()
        }
    }

    /// ハプティックフィードバックを発火
    func triggerHeavyHaptic() {
        hapticService.heavyImpact()
    }

    /// アニメーション抑制状態を設定
    func setAnimationSuppression(_ suppressed: Bool) {
        shouldSuppressAnimation = suppressed
    }

    /// セッション完了アニメーション抑制状態を設定
    func setSessionFinishedAnimationSuppression(_ suppressed: Bool) {
        shouldSuppressSessionFinishedAnimation = suppressed
    }

    /// アニメーション状態をリセット
    func resetAnimationState() {
        flashStars = false
        shouldSuppressAnimation = false
        shouldSuppressSessionFinishedAnimation = false
    }
}
