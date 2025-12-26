//
//  DailyTimelineGestureHandler.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/01/01.
//

import SwiftUI

/// DailyTimelineViewのジェスチャー処理を担当するHandler
struct DailyTimelineGestureHandler {

    // MARK: - Dependencies
    private let navRouter: NavRouting

    init(navRouter: NavRouting = LegacyNavRouter.shared) {
        self.navRouter = navRouter
    }

    // MARK: - Gesture Methods

    /// バックスワイプジェスチャー
    func backSwipeGesture() -> some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                // 左端から右方向へのスワイプを検出
                if value.startLocation.x < 50 && value.translation.width > 100 {
                    navRouter.pop()
                }
            }
    }
}
