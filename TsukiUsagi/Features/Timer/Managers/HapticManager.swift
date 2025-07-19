//
//  HapticManager.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/28
//

import UIKit

/// HapticManager: 端末の触覚フィードバックを管理するシングルトン
class HapticManager {
    static let shared = HapticManager()

    // MARK: - Private Properties

    /// 事前に作成したジェネレーターインスタンス
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        // アプリ起動時に全ジェネレーターを事前準備
        prepareAllGenerators()
    }

    // MARK: - Private Methods

    /// 全ジェネレーターを事前準備
    private func prepareAllGenerators() {
        heavyGenerator.prepare()
        lightGenerator.prepare()
        mediumGenerator.prepare()
        notificationGenerator.prepare()
    }

    /// 使用後のジェネレーターを再準備（非同期）
    private func rePrepareGenerator(_ generator: UIImpactFeedbackGenerator) {
        DispatchQueue.global(qos: .utility).async {
            generator.prepare()
        }
    }

    private func rePrepareNotificationGenerator() {
        DispatchQueue.global(qos: .utility).async {
            self.notificationGenerator.prepare()
        }
    }

    // MARK: - Public Methods

    /// ボタン用
    /// 呼び出し方 -> HapticManager.shared.buttonTapFeedback()
    func buttonTapFeedback() {
        heavyImpact()
    }

    /// ブルッとさせる：重いとはいえそこまで重くない
    func heavyImpact() {
        heavyGenerator.impactOccurred()
        rePrepareGenerator(heavyGenerator)
    }

    // △△ 基本はここまで
    // ▽▽ option

    /// 軽いハプティックフィードバック ※本当に軽すぎて手に持ってないとわからない
    func lightImpact() {
        lightGenerator.impactOccurred()
        rePrepareGenerator(lightGenerator)
    }

    /// 中程度のハプティックフィードバック
    func mediumImpact() {
        mediumGenerator.impactOccurred()
        rePrepareGenerator(mediumGenerator)
    }

    /// カスタムスタイルのハプティックフィードバック
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .heavy:
            heavyImpact()
        case .light:
            lightImpact()
        case .medium:
            mediumImpact()
        case .soft:
            // softスタイルは新規作成（使用頻度が低いため）
            let gen = UIImpactFeedbackGenerator(style: .soft)
            gen.prepare()
            gen.impactOccurred()
        case .rigid:
            // rigidスタイルは新規作成（使用頻度が低いため）
            let gen = UIImpactFeedbackGenerator(style: .rigid)
            gen.prepare()
            gen.impactOccurred()
        @unknown default:
            // 将来のスタイルに対応
            let gen = UIImpactFeedbackGenerator(style: style)
            gen.prepare()
            gen.impactOccurred()
        }
    }

    // MARK: - Notification Feedback

    /// 成功通知フィードバック
    func successNotification() {
        notificationGenerator.notificationOccurred(.success)
        rePrepareNotificationGenerator()
    }

    // コンッとさせる：警告通知フィードバック
    func warningNotification() {
        notificationGenerator.notificationOccurred(.warning)
        rePrepareNotificationGenerator()
    }

    /// エラー通知フィードバック
    func errorNotification() {
        notificationGenerator.notificationOccurred(.error)
        rePrepareNotificationGenerator()
    }

    /// カスタム通知フィードバック
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
        rePrepareNotificationGenerator()
    }
}
