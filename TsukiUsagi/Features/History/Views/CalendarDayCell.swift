import SwiftUI
import Foundation

struct CalendarDayCell: View {
    let date: Date
    let dailyHistory: DailyHistory?
    let isSelected: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 2) {
            // 日付（大きく表示）
            Text("\(calendar.component(.day, from: date))")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(textColor)

            // 活動インジケーター
            activityIndicator()
        }
        .frame(width: 44, height: 44)
        .background(backgroundColor)
        .clipShape(Circle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    @ViewBuilder
    private func activityIndicator() -> some View {
        if let history = dailyHistory, history.hasRecords {
            if isToday {
                // 今日の場合は点滅アニメーション
                TimelineView(.animation(minimumInterval: 0.1)) { timeline in
                    let timeInterval = timeline.date.timeIntervalSinceReferenceDate
                    let pulseOpacity = 0.6 + 0.4 * sin(timeInterval * 1.5)

                    Circle()
                        .fill(history.activityIntensity.color)
                        .frame(width: history.activityIntensity.indicatorSize)
                        .opacity(pulseOpacity)
                }
            } else {
                // 通常の表示
                Circle()
                    .fill(history.activityIntensity.color)
                    .frame(width: history.activityIntensity.indicatorSize)
            }
        } else {
            // 記録なしの場合は何も表示しない
            Spacer().frame(height: 6)
        }
    }

    // MARK: - Computed Properties

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return DesignTokens.MoonColors.accentBlue
        } else {
            return DesignTokens.MoonColors.textPrimary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return DesignTokens.MoonColors.accentBlue
        } else if isToday {
            return DesignTokens.MoonColors.accentBlue.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}
