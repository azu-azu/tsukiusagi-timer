import SwiftUI
import Foundation

struct DailyDetailView: View {
    let date: Date
    let dailyHistory: DailyHistory?

    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Text(date.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(DesignTokens.Fonts.labelBold)
                    .foregroundColor(DesignTokens.SkyToneColors.textPrimary)

                Spacer()

                NavigationLink(destination: DailyTimelineView(targetDate: date)) {
                    Text(Copy.Link.openDaily)
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.accentBlue)
                }
            }

            // 詳細内容
            if let history = dailyHistory, history.hasRecords {
                dailySummaryContent(history)
            } else {
                Text(Labels.State.noRecordsForThisDay)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignTokens.SkyToneColors.cardGradient)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func dailySummaryContent(_ history: DailyHistory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 総時間とセッション数
            HStack {
                Text(String(format: Copy.Label.total, TimeFormatters.totalText(history.totalMinutes)))
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.SkyToneColors.textPrimary)

                Spacer()

                Text(LocalizedStringKey("history_detail_sessions \(history.sessionCount)"))
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
            }

            // 上位アクティビティ
            if !history.topActivities.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(history.topActivities.prefix(3)), id: \.self) { activity in
                        HStack {
                            Text("• \(activity)")
                                .font(DesignTokens.Fonts.caption)
                                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)

                            Spacer()

                            if let minutes = history.activities[activity] {
                                Text(TimeFormatters.totalText(minutes))
                                    .font(DesignTokens.Fonts.caption)
                                    .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
    }
}
