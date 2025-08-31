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
        VStack(spacing: 4) {
            // 月ナビゲーションヘッダー（最小限のパディングでエッジ寄せ）
            monthNavigationHeader()
                .padding(.horizontal, 8)
                .padding(.top, 6)

            // 曜日ヘッダー
            weekdayHeader()
                .padding(.horizontal, 8)
                .padding(.bottom, 2)

            // カレンダーグリッド（エッジ to エッジ）
            calendarGridView(for: selectedMonth)
                .padding(.horizontal, 8)

            // 選択日の詳細表示
            if let selectedDate = selectedDate {
                DailyDetailView(
                    date: selectedDate,
                    dailyHistory: dailyHistories[calendar.startOfDay(for: selectedDate)]
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.top, 12)
            }

            // 下部余白を確保
            Spacer(minLength: 48)
        }
        .contentShape(Rectangle())
        .highPriorityGesture(monthSwipeGesture())
        .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
        .onAppear { loadMonthData() }
        .onChange(of: selectedMonth) { loadMonthData() }
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
                .contentTransition(.opacity)

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
        HStack(spacing: 0) {
            ForEach(CalendarUtilities.weekdays(), id: \.self) { weekday in
                Text(weekday)
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: DesignTokens.Calendar.weekdayHeight)
    }

    // MARK: - Calendar Grid

    @ViewBuilder
    private func calendarGridView(for month: Date) -> some View {
        let startOfMonth = CalendarUtilities.startOfMonth(for: month)
        // Align first day of month to correct weekday column
        let firstWeekday = calendar.firstWeekday // 1=Sunday (typically)
        let weekdayOfFirst = calendar.component(.weekday, from: startOfMonth) // 1...7
        let leadingSpacers = (weekdayOfFirst - firstWeekday + 7) % 7

        let dates = generateCalendarDates(for: month)
        let totalCells = leadingSpacers + dates.count
        let trailingSpacers = (7 - (totalCells % 7)) % 7

        LazyVGrid(columns: columns, spacing: 6) {
            // leading empty cells
            ForEach(0..<leadingSpacers, id: \.self) { _ in
                Color.clear.frame(width: 44, height: 44)
            }

            // month dates
            ForEach(dates, id: \.self) { date in
                CalendarDayCell(
                    date: date,
                    dailyHistory: dailyHistories[calendar.startOfDay(for: date)],
                    isSelected: isSelected(date),
                    isToday: CalendarUtilities.isToday(date)
                )
                .onTapGesture { selectDate(date) }
            }

            // trailing empty cells to complete the last row
            ForEach(0..<trailingSpacers, id: \.self) { _ in
                Color.clear.frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Helper Methods

    private func loadMonthData() {
        dailyHistories = historyVM.getCalendarDailyHistories(for: selectedMonth)

        // 初回表示時、当月かつ本日に記録がある場合は自動で詳細を表示
        if selectedDate == nil && calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month) {
            let todayStart = calendar.startOfDay(for: Date())
            if let todayHistory = dailyHistories[todayStart], todayHistory.hasRecords {
                selectedDate = todayStart
            }
        }
    }

    private func generateCalendarDates(for month: Date) -> [Date] {
        // 当月のみの日付を生成（他月は表示しない）
        return CalendarUtilities.generateMonthDates(for: month)
    }

    private func changeMonth(by offset: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: offset, to: selectedMonth) else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            selectedMonth = newMonth
            selectedDate = nil
        }
    }

    // MARK: - Gestures
    private func monthSwipeGesture() -> some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = abs(value.translation.height)
                guard abs(horizontal) > vertical else { return }
                if horizontal < -30 {
                    changeMonth(by: 1)
                } else if horizontal > 30 {
                    changeMonth(by: -1)
                }
            }
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
