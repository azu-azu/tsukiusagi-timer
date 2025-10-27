//
//  TimerActivityAttributes.swift
//  TsukiUsagiLiveActivity
//
//  Created by Kazumi on 2025/01/19.
//

import ActivityKit
import Foundation

/// Live Activity のデータモデル
///
/// TimerViewModelからタイマー開始時にLiveActivityManagerを通じて
/// ActivityAttributesとして渡され、Widget側で表示される
struct TimerActivityAttributes: ActivityAttributes {
    /// 動的なコンテンツ状態（DateIntervalによる自動カウントダウン用）
    struct ContentState: Codable, Hashable {
        /// タイマー終了時刻（これから減算してカウントダウン）
        var endsAt: Date
        /// 一時停止中かどうか
        var isPaused: Bool
    }

    /// セッション種別（"Work", "Study", "Read", "Break" など）
    /// これは動的ではなく、セッション開始時に一度設定される
    var sessionKind: String
}

