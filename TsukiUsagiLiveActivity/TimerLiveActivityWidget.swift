//
//  TimerLiveActivityWidget.swift
//  TsukiUsagiLiveActivity
//
//  Created by Kazumi on 2025/01/19.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in

            // ===== Lock Screen / Banner =====
            let cardCorner: CGFloat = 26
            let headerH: CGFloat = 44
            let bodyH: CGFloat = 54

            ZStack {
                // ベース（角丸カード）
                RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                    .fill(Color.black.opacity(0.92))

                VStack(spacing: 0) {

                    // ── ヘッダー：ダークグレー + セッション名（中央） ──
                    ZStack {
                        Color(white: 0.10)
                        Text(context.attributes.sessionKind.capitalized)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: headerH)

                    // ── ボディ：半透明イエロー ──
                    GeometryReader { geo in
                        ZStack {
                            Color.yellow.opacity(0.26)

                            // 中央塊を座標指定で“絶対中央”に配置
                            HStack(spacing: 10) {
                                Image(systemName: "moon.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.yellow.opacity(0.95))

                                if context.state.isPaused, let secs = context.state.remainingSeconds {
                                    let minutes = secs / 60
                                    let seconds = secs % 60
                                    Text("\(minutes):\(String(format: "%02d", seconds))")
                                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                } else {
                                    Text(context.state.endsAt, style: .timer)
                                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                        .contentTransition(.numericText())
                                }
                            }
                            .fixedSize()
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        }
                    }
                    .frame(height: bodyH)
                }
                // 枠線（いちばん外）
                // .overlay(
                //     RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                //         .inset(by: 0.8)
                //         .stroke(Color.yellow.opacity(0.55), lineWidth: 1.6)
                // )
            }
            .contentMargins(.all, 0)
            .activitySystemActionForegroundColor(.yellow)
            .widgetURL(URL(string: "tsukiusagi://timer"))

        } dynamicIsland: { context in
            // ===== Dynamic Island =====
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    // Pause時は remainingSeconds の固定値を表示
                    if context.state.isPaused, let secs = context.state.remainingSeconds {
                        let minutes = secs / 60
                        let seconds = secs % 60
                        Text("\(minutes):\(String(format: "%02d", seconds))")
                            .font(.title3)
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .layoutPriority(1)
                            .padding(.leading, 8)
                    } else {
                        Text(context.state.endsAt, style: .timer)
                            .font(.title3)
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .layoutPriority(1)
                            .padding(.leading, 8)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(Color(red: 1.0, green: 1.0, blue: 0.33))
                        Text(context.attributes.sessionKind.capitalized)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
                }
            } compactLeading: {
                ZStack {
                    Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                    Image(systemName: "moon.fill")
                        .resizable().scaledToFit()
                        .padding(6)
                        .foregroundColor(Color(red: 1.0, green: 1.0, blue: 0.33))
                }
                .frame(width: 32, height: 32)
                .widgetURL(URL(string: "tsukiusagi://timer"))
            } compactTrailing: {
                // Pause時は remainingSeconds の固定値を表示
                if context.state.isPaused, let secs = context.state.remainingSeconds {
                    let minutes = secs / 60
                    let seconds = secs % 60
                    Text("\(minutes):\(String(format: "%02d", seconds))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text(context.state.endsAt, style: .timer)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            } minimal: {
                Image(systemName: "moon.fill")
                    .resizable().scaledToFit().padding(4)
                    .foregroundColor(Color(red: 1.0, green: 1.0, blue: 0.33))
            }
        }
    }
}
