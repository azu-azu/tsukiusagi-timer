import SwiftUI
import Foundation

struct CalendarDayCell: View {
    let date: Date
    let dailyHistory: DailyHistory?
    let isSelected: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            // Filled circle background for active/completed days
            circleBackground

            // Day number
            Text("\(calendar.component(.day, from: date))")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(textColor)
        }
        .frame(width: 44, height: 44)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // 背景サークル
    @ViewBuilder
    private var circleBackground: some View {
        let hasRecord = dailyHistory?.hasRecords == true
        if isSelected {
            Circle().fill(DesignTokens.MoonColors.accentBlue)
        } else if isToday {
            Circle()
                .stroke(DesignTokens.MoonColors.accentBlue, lineWidth: 2)
                .background(Circle().fill(hasRecord ? historyColor.opacity(0.2) : Color.clear))
        } else if hasRecord {
            Circle().fill(historyColor.opacity(0.85))
        } else {
            Circle().fill(Color.clear)
        }
    }

    // MARK: - Computed Properties

    private var textColor: Color {
        if isSelected { return DesignTokens.PureColors.textWhite }
        if isToday { return DesignTokens.MoonColors.accentBlue }
        return DesignTokens.MoonColors.textPrimary
    }

    private var historyColor: Color {
        // Use intensity color if available; otherwise muted accent for visibility
        if let history = dailyHistory, history.hasRecords {
            return history.activityIntensity.color
        }
        return DesignTokens.MoonColors.textMuted
    }
}
