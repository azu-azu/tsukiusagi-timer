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
        guard let newMonth = calendar.date(
            byAdding: .month,
            value: offset,
            to: selectedMonth
        ) else {
            return
        }
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
