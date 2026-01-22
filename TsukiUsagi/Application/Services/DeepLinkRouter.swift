//
//  DeepLinkRouter.swift
//  TsukiUsagi
//
//  Created by Kazumi on 2025/01/19.
//

import SwiftUI

/// URL Scheme を処理してタイマー画面にナビゲート
///
/// Live Activity や通知からのタップで、アプリ復帰後に
/// タイマー画面を開くためのDeep Link処理を担当
final class DeepLinkRouter {
    // MARK: - Singleton
    static let shared = DeepLinkRouter()

    // MARK: - Published Properties

    /// タイマー画面を開くトリガー
    @Published private(set) var shouldOpenTimer: Bool = false

    // MARK: - Private Initialization

    private init() {}

    // MARK: - Public Methods

    /// Deep Link URLを処理
    ///
    /// - Parameter url: 開かれたURL
    func handle(url: URL) {
        // URL Scheme検証
        guard url.scheme == "tsukiusagi" else {
            return
        }

        // Hostに応じて処理分岐
        switch url.host {
        case "timer":
            // タイマー画面を開く
            shouldOpenTimer = true

        default:
            break
        }
    }

    /// タイマー画面が開かれた後のリセット
    func reset() {
        shouldOpenTimer = false
    }
}
