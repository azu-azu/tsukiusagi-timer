//
//  TimerLiveActivityWidget.swift
//  TsukiUsagiLiveActivity
//
//  Created by Kazumi on 2025/01/19.
//

import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity Widget の本体
struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // MARK: - Lock Screen / Banner 表示
            VStack(spacing: 6) {
                // セッション名（補助テキスト）
                Text(context.attributes.sessionKind.capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                // 残り時間（中央、大きく、モノスペース）
                Text(timerInterval: Date.now...context.state.endsAt,
                     countsDown: true)
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundColor(.white)
            }
            .widgetURL(URL(string: "tsukiusagi://timer"))

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded（拡張表示：Island本体）
                DynamicIslandExpandedRegion(.leading) {
                    // 左側：🌙アイコン + セッション名
                    HStack(spacing: 8) {
                        Image(systemName: "moon.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(Color(red: 1.0, green: 1.0, blue: 0.33)) // #ffff55

                        Text(context.attributes.sessionKind.capitalized)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    // 右端：残り時間
                    Text(timerInterval: Date.now...context.state.endsAt,
                         countsDown: true)
                        .font(.title3)
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .padding(.trailing, 8)
                }

            } compactLeading: {
                // MARK: - Compact Leading（Island左側）
                Text(timerInterval: Date.now...context.state.endsAt,
                     countsDown: true)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .lineLimit(1)

            } compactTrailing: {
                // MARK: - Compact Trailing（Island右側：丸い🌙ロゴ）
                ZStack {
                    // 円形枠（薄いストローク）
                    Circle()
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)

                    // 🌙アイコン
                    Image(systemName: "moon.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                        .foregroundColor(Color(red: 1.0, green: 1.0, blue: 0.33)) // #ffff55
                }
                .frame(width: 32, height: 32)
                .widgetURL(URL(string: "tsukiusagi://timer"))

            } minimal: {
                // MARK: - Minimal（最小表示：🌙ロゴのみ）
                Image(systemName: "moon.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(4)
                    .foregroundColor(Color(red: 1.0, green: 1.0, blue: 0.33)) // #ffff55
            }
        }
    }
}

