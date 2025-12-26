//
//  LegacyNavRouter.swift
//  TsukiUsagi
//
//  UIKit navigation operations isolated from SwiftUI views.
//  SwiftUI views should use this router instead of directly accessing UIKit hierarchy.
//
//  Usage:
//    LegacyNavRouter.shared.pop()
//    LegacyNavRouter.shared.setBackSwipeEnabled(false)
//

import UIKit

// MARK: - Protocol

/// ナビゲーション操作の抽象化
/// SwiftUI ViewはUIKit階層に直接アクセスせず、このプロトコルを使用する
protocol NavRouting {
    /// 前の画面に戻る
    func pop(animated: Bool)
    /// バックスワイプジェスチャーの有効/無効を設定
    func setBackSwipeEnabled(_ enabled: Bool)
}

extension NavRouting {
    func pop() { pop(animated: true) }
}

// MARK: - Implementation

/// UIKit UINavigationControllerへのアクセスを隔離するRouter
/// SwiftUI側からはUIKit階層を直接探索しない
final class LegacyNavRouter: NavRouting {

    // MARK: - Singleton
    static let shared = LegacyNavRouter()
    private init() {}

    // MARK: - NavRouting

    func pop(animated: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            self?.findNavigationController()?.popViewController(animated: animated)
        }
    }

    func setBackSwipeEnabled(_ enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let navController = self?.findNavigationController(),
                  let gestureRecognizer = navController.interactivePopGestureRecognizer else {
                return
            }
            gestureRecognizer.isEnabled = enabled
        }
    }

    // MARK: - Private

    /// 現在のUINavigationControllerを検索
    /// UIKit階層の探索はこのメソッドに閉じ込める
    private func findNavigationController() -> UINavigationController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return findNavigationController(in: window.rootViewController)
    }

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
}
