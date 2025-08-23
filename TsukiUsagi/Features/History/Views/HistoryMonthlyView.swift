import SwiftUI

struct HistoryMonthlyView: View {
    @EnvironmentObject var historyVM: HistoryViewModel

    // Stable paging model to avoid jank: fixed months array + index
    @State private var months: [Date] = []
    @State private var currentIndex: Int = 0

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            // Page-style month pager (stable pages by index)
            TabView(selection: $currentIndex) {
                ForEach(months.indices, id: \.self) { idx in
                    VStack(alignment: .leading, spacing: 0) {
                        MonthlyPage(month: months[idx])
                            .padding(.horizontal, 8)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .tag(idx)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .onAppear { ensureMonthsInitialized() }
    }

    // Initialize a stable window of months around today
    private func ensureMonthsInitialized() {
        guard months.isEmpty else { return }
        let center = startOfMonth(Date())
        let window = (-12...12).compactMap { offset in
            calendar.date(byAdding: .month, value: offset, to: center)
        }
        months = window
        currentIndex = window.firstIndex(of: center) ?? (window.count / 2)
    }

    private func startOfMonth(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    // MARK: - Page
    @ViewBuilder
    private func MonthlyPage(month: Date) -> some View {
        let summary = historyVM.getCalendarMonthSummary(for: month)
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(month.formatted(.dateTime.year().month(.wide)))
                    .font(DesignTokens.Fonts.labelBold)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                Spacer()
            }

            // Totals card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total: \(TimeFormatters.totalText(summary.totalMinutes))")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    Spacer()
                    Text("\(summary.totalSessions) sessions")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                }
                Text("Active days: \(summary.activeDays)")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
            .roundedCard()

            // Weekly totals (simple bar list)
            WeeklyTotalsList(month: month)
                .roundedCard()
        }
        // Minimal gap below tabs
        .padding(.top, 0)
    }
}

// MARK: - Weekly Totals
private struct WeeklyTotalsList: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    let month: Date
    private let calendar = Calendar.current

    var body: some View {
        let buckets = weeklyBuckets()
        let maxVal = max(buckets.map { $0.totalMinutes }.max() ?? 1, 1)

        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Summary")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)

            ForEach(buckets) { bucket in
                HStack(spacing: 8) {
                    Text(bucket.label)
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                        .frame(width: 80, alignment: .leading)

                    // bar
                    GeometryReader { geo in
                        let maxWidth = max(1, geo.size.width)
                        let ratio = min(1, max(0, Double(bucket.totalMinutes) / Double(maxVal)))
                        let barWidth = CGFloat(ratio) * maxWidth
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DesignTokens.WhiteColors.stroke)
                                .opacity(0.2)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DesignTokens.MoonColors.accentBlue)
                                .frame(width: max(1, barWidth), height: 8)
                        }
                    }
                    .frame(height: 12)

                    Text(TimeFormatters.totalText(bucket.totalMinutes))
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                        .monospacedDigit()
                        .frame(width: 80, alignment: .trailing)
                }
            }
        }
    }

    private func weeklyBuckets() -> [WeeklyBucket] {
        // Split the month into weeks (starting Sunday per current Calendar settings)
        let days = historyVM.getCalendarDailyHistories(for: month)
        // sort keys
        let sortedKeys = days.keys.sorted()
        guard let first = sortedKeys.first else { return [] }
        var buckets: [WeeklyBucket] = []

        var weekIndex = 0
        var currentWeekTotal = 0
        var currentWeekStart = first

        for key in sortedKeys {
            let comp = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: key)
            let compPrev = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: currentWeekStart)
            if comp.weekOfYear != compPrev.weekOfYear || comp.yearForWeekOfYear != compPrev.yearForWeekOfYear {
                // flush previous
                buckets.append(
                    WeeklyBucket(
                        index: weekIndex,
                        label: weekLabel(currentWeekStart),
                        totalMinutes: currentWeekTotal
                    )
                )
                weekIndex += 1
                currentWeekStart = key
                currentWeekTotal = 0
            }
            currentWeekTotal += days[key]?.totalMinutes ?? 0
        }
        // flush last
        buckets.append(
            WeeklyBucket(
                index: weekIndex,
                label: weekLabel(currentWeekStart),
                totalMinutes: currentWeekTotal
            )
        )
        return buckets
    }

    private func weekLabel(_ date: Date) -> String {
        let start = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        ) ?? date
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let fmt: Date.FormatStyle = .dateTime.month(.abbreviated).day()
        return "\(start.formatted(fmt)) - \(end.formatted(fmt))"
    }

    // Removed maxTotal() to avoid repeated recomputation per row
}

// MARK: - Weekly Bucket Model
private struct WeeklyBucket: Identifiable {
    let index: Int
    let label: String
    let totalMinutes: Int
    var id: Int { index }
}
