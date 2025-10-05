//
//  TimerAnimationControllerProtocol.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/01/01.
//

import Combine
import Foundation

/// タイマーアニメーション制御のプロトコル
/// 星の点滅、セッション完了アニメーション、ハプティックフィードバックを管理
@MainActor
protocol TimerAnimationControllerProtocol: ObservableObject {
    // MARK: - Published Properties

    /// 星の点滅アニメーション状態
    var flashStars: Bool { get set }

    /// アニメーション抑制フラグ（復元時など）
    var shouldSuppressAnimation: Bool { get set }

    /// セッション完了アニメーション抑制フラグ
    var shouldSuppressSessionFinishedAnimation: Bool { get set }

    /// スタートパルスアニメーション用のSubject
    var startPulse: PassthroughSubject<Void, Never> { get }

    // MARK: - Public Methods

    /// スタートアニメーションを発火（星の点滅 + パルス）
    func triggerStartAnimations()

    /// セッション完了アニメーションを発火
    func triggerSessionFinishedAnimations()

    /// ハプティックフィードバックを発火
    func triggerHeavyHaptic()

    /// アニメーション抑制状態を設定
    func setAnimationSuppression(_ suppressed: Bool)

    /// セッション完了アニメーション抑制状態を設定
    func setSessionFinishedAnimationSuppression(_ suppressed: Bool)

    /// アニメーション状態をリセット
    func resetAnimationState()
}
