//
//  DailyTimelineGestureHandler.swift
//  TsukiUsagi
//
//  Created by Kazumi on 2025/01/01.
//

import SwiftUI
import UIKit

/// DailyTimelineViewのジェスチャー処理を担当するHandler
struct DailyTimelineGestureHandler {

    // MARK: - Gesture Methods

    /// バックスワイプジェスチャー
    func backSwipeGesture() -> some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                // 左端から右方向へのスワイプを検出
                if value.startLocation.x < 50 && value.translation.width > 100 {
                    navigateBack()
                }
            }
    }

    /// ナビゲーション戻る処理
    private func navigateBack() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        findNavigationController(in: window.rootViewController)?.popViewController(animated: true)
    }

    /// ナビゲーションコントローラー検索
    private func findNavigationController(in viewController: UIViewController?) -> UINavigationController? {
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }

        if let tabBarController = viewController as? UITabBarController {
            return findNavigationController(in: tabBarController.selectedViewController)
        }

        for child in viewController?.children ?? [] {
            if let found = findNavigationController(in: child) {
                return found
            }
        }

        return nil
    }

    /// バックスワイプジェスチャーを無効化
    func disableBackSwipeGesture() {
        // ジェスチャー無効化の実装
        // 必要に応じて実装
    }

    /// バックスワイプジェスチャーを有効化
    func enableBackSwipeGesture() {
        // ジェスチャー有効化の実装
        // 必要に応じて実装
    }
}
