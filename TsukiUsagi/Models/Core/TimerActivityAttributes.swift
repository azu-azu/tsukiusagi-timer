//
//  TimerActivityAttributes.swift
//  TsukiUsagi
//
//  Created by Kazumi on 2025/01/20.
//

import ActivityKit
import Foundation

/// Live Activity のデータモデル
///
/// App と Widget Extension で共有する
/// TimerViewModelからタイマー開始時にLiveActivityManagerを通じて
/// ActivityAttributesとして渡され、Widget側で表示される
struct TimerActivityAttributes: ActivityAttributes {
    /// 動的なコンテンツ状態（DateIntervalによる自動カウントダウン用）
    struct ContentState: Codable, Hashable {
        /// タイマー終了時刻（これから減算してカウントダウン）
        var endsAt: Date
        /// 一時停止中かどうか
        var isPaused: Bool
        /// Pause中の固定残り秒（Pause時のみ有効）。nilなら未使用
        var remainingSeconds: Int?
    }

    /// セッション種別（"Work", "Study", "Read", "Break" など）
    /// これは動的ではなく、セッション開始時に一度設定される
    var sessionKind: String
}

