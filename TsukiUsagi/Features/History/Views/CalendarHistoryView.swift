import SwiftUI
import Foundation

struct CalendarHistoryView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    @State private var selectedMonth = Date()
    @State private var selectedDate: Date?
    @State private var dailyHistories: [Date: DailyHistory] = [:]

    // Smooth paging model for months
    @State private var months: [Date] = []
    @State private var currentIndex: Int = 0

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            // 月ナビゲーションヘッダー（最小限のパディングでエッジ寄せ）
            monthNavigationHeader()
                .padding(.horizontal, 8)
                .padding(.top, 8)

            // 曜日ヘッダー
            weekdayHeader()
                .padding(.horizontal, 8)

            // カレンダーグリッド（ページングでスムーズに月移動）
            TabView(selection: $currentIndex) {
                ForEach(months.indices, id: \.self) { idx in
                    calendarGridView(for: months[idx])
                        .padding(.horizontal, 8)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.snappy(duration: 0.28, extraBounce: 0), value: currentIndex)

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
        .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
        .onAppear {
            ensureMonthsInitialized()
            selectedMonth = months[safe: currentIndex] ?? selectedMonth
            loadMonthData()
        }
        .onChange(of: selectedMonth) { loadMonthData() }
        .onChange(of: currentIndex) { _, newIndex in
            if let month = months[safe: newIndex] {
                selectedMonth = month
                selectedDate = nil
            }
        }
    }

    // MARK: - Month Navigation Header

    @ViewBuilder
    private func monthNavigationHeader() -> some View {
        HStack {
            Button {
                pageChange(by: -1)
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
                pageChange(by: 1)
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
        // Get histories for this page's month to avoid pop-in during swipe
        let map = historyVM.getCalendarDailyHistories(for: month)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(generateCalendarDates(for: month), id: \.self) { date in
                CalendarDayCell(
                    date: date,
                    dailyHistory: map[calendar.startOfDay(for: date)],
                    isSelected: isSelected(date),
                    isToday: CalendarUtilities.isToday(date)
                )
                .onTapGesture { selectDate(date) }
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

    private func pageChange(by delta: Int) {
        let newIndex = max(0, min((months.count - 1), currentIndex + delta))
        guard newIndex != currentIndex else { return }
        currentIndex = newIndex
    }

    // MARK: - Months window setup
    private func ensureMonthsInitialized() {
        guard months.isEmpty else { return }
        let center = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let window = (-12...12).compactMap { offset in
            calendar.date(byAdding: .month, value: offset, to: center)
        }
        months = window
        currentIndex = window.firstIndex(of: center) ?? (window.count / 2)
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
