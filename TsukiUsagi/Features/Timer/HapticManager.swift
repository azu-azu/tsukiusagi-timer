//
//  HapticManager.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/28
//

import UIKit

/// ハプティックフィードバックを管理するユーティリティクラス
final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    /// ボタン用
    // 呼び出し方 -> HapticManager.shared.buttonTapFeedback()
    func buttonTapFeedback() {
        heavyImpact()
    }

    /// ブルッとさせる：重いとはいえそこまで重くない
    func heavyImpact() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.prepare()
        gen.impactOccurred()
    }

    // △△ 基本はここまで
    // ▽▽ option

    /// 軽いハプティックフィードバック ※本当に軽すぎて手に持ってないとわからない
    func lightImpact() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred()
    }

    /// 中程度のハプティックフィードバック
    func mediumImpact() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.prepare()
        gen.impactOccurred()
    }

    /// カスタムスタイルのハプティックフィードバック
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// 成功通知フィードバック
    func successNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    // コンッとさせる：警告通知フィードバック
    func warningNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    /// エラー通知フィードバック
    func errorNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    /// カスタム通知フィードバック
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
