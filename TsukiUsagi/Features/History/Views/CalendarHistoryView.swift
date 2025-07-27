import SwiftUI
import Foundation

struct CalendarHistoryView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    @State private var selectedMonth = Date()
    @State private var selectedDate: Date?
    @State private var dailyHistories: [Date: DailyHistory] = [:]

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // カレンダーカード（月ナビゲーション + 曜日ヘッダー + グリッド）
                VStack(spacing: 0) {
                    // 月ナビゲーションヘッダー
                    monthNavigationHeader()

                    // 曜日ヘッダー
                    weekdayHeader()

                    // カレンダーグリッド
                    calendarGridView()
                }
                .padding()
                .background(DesignTokens.CosmosColors.cardBackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .padding(.horizontal)
                .padding(.top)

                // 選択日の詳細表示
                if let selectedDate = selectedDate {
                    DailyDetailView(
                        date: selectedDate,
                        dailyHistory: dailyHistories[calendar.startOfDay(for: selectedDate)]
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.top, 16)
                }
                
                // 下部余白を確保
                Spacer(minLength: 100)
            }
        }
        .scrollIndicators(.hidden)
        .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
        .onAppear {
            loadMonthData()
        }
        .onChange(of: selectedMonth) {
            loadMonthData()
        }
    }

    // MARK: - Month Navigation Header

    @ViewBuilder
    private func monthNavigationHeader() -> some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthTitle())
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
            .buttonStyle(.plain)
            .disabled(isCurrentMonth())
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Weekday Header

    @ViewBuilder
    private func weekdayHeader() -> some View {
        HStack {
            ForEach(CalendarUtilities.weekdays(), id: \.self) { weekday in
                Text(weekday)
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .frame(height: DesignTokens.Calendar.weekdayHeight)
    }

    // MARK: - Calendar Grid

    @ViewBuilder
    private func calendarGridView() -> some View {
        LazyVGrid(columns: columns, spacing: DesignTokens.Calendar.cellSpacing) {
            ForEach(generateCalendarDates(), id: \.self) { date in
                CalendarDayCell(
                    date: date,
                    dailyHistory: dailyHistories[calendar.startOfDay(for: date)],
                    isSelected: isSelected(date),
                    isToday: CalendarUtilities.isToday(date)
                )
                .onTapGesture {
                    selectDate(date)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helper Methods

    private func loadMonthData() {
        dailyHistories = historyVM.getCalendarDailyHistories(for: selectedMonth)
    }

    private func generateCalendarDates() -> [Date] {
        // 当月のみの日付を生成（他月は表示しない）
        return CalendarUtilities.generateMonthDates(for: selectedMonth)
    }

    private func changeMonth(by offset: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: offset, to: selectedMonth) else { return }
        selectedMonth = newMonth
        selectedDate = nil // 選択をクリア
    }

    private func monthTitle() -> String {
        selectedMonth.formatted(.dateTime.year().month(.wide))
    }

    private func isCurrentMonth() -> Bool {
        calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private func selectDate(_ date: Date) {
        let startOfDay = calendar.startOfDay(for: date)
        if selectedDate == startOfDay {
            selectedDate = nil // 同じ日をタップしたら選択解除
        } else {
            selectedDate = startOfDay
        }
    }
}

// MARK: - Calendar Day Cell

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
                .font(.system(size: 18, weight: .medium))
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

// MARK: - Daily Detail View

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
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                Spacer()

                NavigationLink(destination: DailyTimelineView(targetDate: date)) {
                    Text("View Details")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.accentBlue)
                }
            }

            // 詳細内容
            if let history = dailyHistory, history.hasRecords {
                dailySummaryContent(history)
            } else {
                Text("No records for this day")
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
        }
        .padding()
        .background(DesignTokens.CosmosColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func dailySummaryContent(_ history: DailyHistory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 総時間とセッション数
            HStack {
                Text("Total: \(TimeFormatters.totalText(history.totalMinutes))")
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                Spacer()

                Text("\(history.sessionCount) sessions")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }

            // 上位アクティビティ
            if !history.topActivities.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(history.topActivities.prefix(3)), id: \.self) { activity in
                        HStack {
                            Text("• \(activity)")
                                .font(DesignTokens.Fonts.caption)
                                .foregroundColor(DesignTokens.MoonColors.textPrimary)

                            Spacer()

                            if let minutes = history.activities[activity] {
                                Text(TimeFormatters.totalText(minutes))
                                    .font(DesignTokens.Fonts.caption)
                                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
    }
}

// 以下のDailyTimelineViewは変更なし
struct DailyTimelineView: View {
    let targetDate: Date
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    @State private var restoreError: String?
    @State private var showRestoreAlert = false

    private let cal = Calendar.current
    private let dayModeCardHeight: CGFloat = 40
    private let dayModeCardSpacing: CGFloat = 2
    private let timeWidth: CGFloat = 100
    private let summaryCardHeight: CGFloat = 50

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Total 表示
                TotalCard(text: TimeFormatters.totalText(totalMinutes()))

                // レコード表示
                dayModeRecordsSection()

                // 集計表示（レコードが複数ある場合のみ）
                if records().count > 1 {
                    activitySummarySection()
                    subtitleSummarySection()
                }

                // メモ部分
                memoSection()
            }
            .padding(.horizontal)
        }
        .navigationTitle(targetDate.formatted(.dateTime.weekday(.wide).month().day()))
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showRestoreAlert) {
            Alert(
                title: Text("Restore Error"),
                message: Text(restoreError ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
        .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
    }

    // MARK: - Records Section

    @ViewBuilder
    private func dayModeRecordsSection() -> some View {
        VStack(alignment: .leading, spacing: dayModeCardSpacing) {
            ForEach(records()) { rec in
                recordRow(rec)
            }
        }
    }

    @ViewBuilder
    private func recordRow(_ rec: SessionRecord) -> some View {
        let isDeleted = historyVM.isDeleted(sessionManager: sessionManager, activity: rec.activity)
        let displayName = historyVM.displayActivity(sessionManager: sessionManager, activity: rec.activity)

        HStack(spacing: 0) {
            Text(rec.start.formatted(date: .omitted, time: .shortened))
                .monospacedDigit()
                .foregroundColor(DesignTokens.MoonColors.textPrimary)

            Spacer().frame(width: 8)

            Image(systemName: "arrow.right")
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            Spacer().frame(width: 8)

            Text(rec.end.formatted(date: .omitted, time: .shortened))
                .monospacedDigit()
                .foregroundColor(DesignTokens.MoonColors.textPrimary)

            Spacer(minLength: 8)

            Text("\(displayName) \(durationMinutes(rec)) min")
                .foregroundColor(isDeleted ? .gray : DesignTokens.MoonColors.textPrimary)
                .opacity(isDeleted ? 0.5 : 1.0)

            if isDeleted {
                Button("Restore") {
                    do {
                        try historyVM.restore(record: rec, sessionManager: sessionManager)
                    } catch {
                        restoreError = error.localizedDescription
                        showRestoreAlert = true
                    }
                }
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.accentBlue)
            }
        }
        .font(DesignTokens.Fonts.label)
        .frame(minHeight: dayModeCardHeight, alignment: .leading)
        .padding(.horizontal, DesignTokens.Padding.cardHorizontal)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(DesignTokens.CosmosColors.cardBackground)
        )
    }

    // MARK: - Data Methods

    private func records() -> [SessionRecord] {
        return historyVM.history
            .filter { rec in
                cal.isDate(rec.start, inSameDayAs: targetDate)
            }
            .sorted { $0.start < $1.start }
    }

    private func totalMinutes() -> Int {
        records().reduce(0) { $0 + durationMinutes($1) }
    }

    private func durationMinutes(_ rec: SessionRecord) -> Int {
        let sec = rec.end.timeIntervalSince(rec.start)
        return max(Int(sec) / 60, 1)
    }

    // MARK: - Summary Sections

    private struct LabelSummary {
        let label: String
        let total: Int
    }

    private func byActivity() -> [LabelSummary] {
        let grouped = Dictionary(grouping: records(), by: \.activity)
        return grouped.map { k, recs in
            LabelSummary(
                label: String(describing: k),
                total: recs.reduce(0) { $0 + durationMinutes($1) }
            )
        }
        .sorted { $0.total > $1.total }
    }

    private func bySubtitle() -> [LabelSummary] {
        let recordsWithSubtitle = records().filter {
            guard let subtitle = $0.subtitle?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
            return !subtitle.isEmpty
        }
        let grouped = Dictionary(grouping: recordsWithSubtitle) { $0.subtitle! }
        return grouped.map { k, recs in
            LabelSummary(
                label: k,
                total: recs.reduce(0) { $0 + durationMinutes($1) }
            )
        }
        .sorted { $0.total > $1.total }
    }

    @ViewBuilder
    private func activitySummarySection() -> some View {
        summarySection(title: "By Activity", summaries: byActivity())
    }

    @ViewBuilder
    private func subtitleSummarySection() -> some View {
        if !bySubtitle().isEmpty {
            summarySection(title: "By Subtitle", summaries: bySubtitle())
        }
    }

    private func summarySection(title: String, summaries: [LabelSummary]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            ForEach(summaries, id: \.label) { s in
                HStack {
                    Text(s.label)
                        .padding(.leading, 8)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    Spacer()
                    Text(TimeFormatters.totalText(s.total))
                        .monospacedDigit()
                        .frame(width: timeWidth, alignment: .trailing)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
                .summaryCardStyle(height: summaryCardHeight)
            }
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private func memoSection() -> some View {
        let memos = records()
            .compactMap { $0.memo?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !memos.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("📝 Memos")
                    .font(DesignTokens.Fonts.sectionTitle)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)

                ForEach(memos, id: \.self) { memo in
                    Text(memo)
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                        .padding(8)
                        .roundedCard()
                }
            }
            .padding(.top, 16)
        }
    }
}

// 共通サマリーカードスタイル
extension View {
    func summaryCardStyle(
        height: CGFloat = 32,
        cornerRadius: CGFloat = 6,
        backgroundColor: Color = DesignTokens.CosmosColors.cardBackground,
        padding: EdgeInsets = EdgeInsets(
            top: 4,
            leading: DesignTokens.Padding.cardHorizontal,
            bottom: 4,
            trailing: DesignTokens.Padding.cardHorizontal
        )
    ) -> some View {
        font(DesignTokens.Fonts.label)
            .padding(padding)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            )
    }
}
