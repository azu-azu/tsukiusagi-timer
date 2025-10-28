import ActivityKit
import SwiftUI
import WidgetKit

struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // ===== Lock Screen / Banner =====
            let cardCorner: CGFloat = 26
            let headerH: CGFloat = 44
            let bodyH:   CGFloat = 54

            ZStack {
                // ベース（角丸カード）
                RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                    .fill(Color.black.opacity(0.92))

                // 上下2段の“面”だけを描く
                VStack(spacing: 0) {
                    // ── ヘッダー（黒寄りグレー） ──
                    ZStack {
                        Color(white: 0.10)
                        Text(context.attributes.sessionKind.capitalized)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: headerH)

                    // ── ボディ（黄色）──
                    ZStack {
                        Color.yellow.opacity(0.26)

                        // ★ この領域の“幾何学・中央”に配置
                        GeometryReader { geo in
                            HStack(spacing: 10) {
                                Image(systemName: "moon.fill")
                                    .resizable().scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.yellow.opacity(0.95))

                                Text(timerInterval: Date.now...context.state.endsAt, countsDown: true)
                                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                            .fixedSize() // 中身の自然幅のまま
                            .position(x: geo.size.width/2, y: geo.size.height/2) // ← 真ん中ドン
                        }
                        .allowsHitTesting(false) // 念のため
                    }
                    .frame(height: bodyH)
                }
                .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
            }
            // 枠線
            // .overlay(
            //     RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
            //         .stroke(Color.yellow.opacity(0.55), lineWidth: 1.6)
            // )
            .contentMargins(.all, 0)
            .activitySystemActionForegroundColor(.yellow)
            .widgetURL(URL(string: "tsukiusagi://timer"))

            // ===== Dynamic Island（そのまま）=====
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(timerInterval: Date.now...context.state.endsAt, countsDown: true)
                        .font(.title3)
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .layoutPriority(1)
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.fill")
                            .resizable().scaledToFit()
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
                Text(timerInterval: Date.now...context.state.endsAt, countsDown: true)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.trailing, -3)
            } minimal: {
                Image(systemName: "moon.fill")
                    .resizable().scaledToFit()
                    .padding(4)
                    .foregroundColor(Color(red: 1.0, green: 1.0, blue: 0.33))
            }
        }
    }
}
