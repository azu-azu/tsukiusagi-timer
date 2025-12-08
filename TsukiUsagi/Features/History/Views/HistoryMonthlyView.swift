import SwiftUI

struct HistoryMonthlyView: View {
    @EnvironmentObject var historyVM: HistoryViewModel

    // Stable paging model with UUID-based Month objects
    @State private var months: [Month] = []
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
                    .id(months[idx].id) // Stable ID for proper view regeneration
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onChange(of: currentIndex) { oldValue, newValue in
                // Page change event handling (analytics, prefetch, etc.)
                handlePageChange(from: oldValue, to: newValue)
            }
        }
        .onAppear { ensureMonthsInitialized() }
    }

    // Initialize a stable window of months around today
    private func ensureMonthsInitialized() {
        guard months.isEmpty else { return }
        months = Month.generateAroundToday(countBefore: 12, countAfter: 12)
        currentIndex = months.firstIndex { $0.isCurrentMonth } ?? (months.count / 2)
    }

    // MARK: - Page Change Handling
    private func handlePageChange(from oldIndex: Int, to newIndex: Int) {
        // Optional: Add analytics tracking, prefetching, or other side effects
        // Example: Analytics.track("month_changed", properties: ["from": oldIndex, "to": newIndex])

        // Optional: Prefetch adjacent months for smoother experience
        prefetchAdjacentMonths(around: newIndex)
    }

    private func prefetchAdjacentMonths(around index: Int) {
        // Optional: Preload data for adjacent months to improve performance
        // This could trigger background data loading for months[index ± 1]
    }

    // MARK: - Navigation Helpers
    private func changeMonth(by delta: Int) {
        let nextIndex = (currentIndex + delta).clamped(to: 0...(months.count - 1))
        currentIndex = nextIndex
    }

    // MARK: - Page
    @ViewBuilder
    private func MonthlyPage(month: Month) -> some View {
        MonthlyPageContent(month: month)
            .task(id: month.id) {
                // Optional: Preload data for this month if needed
                // This runs when the month changes, providing smooth data loading
                await preloadMonthData(for: month)
            }
    }

    private func preloadMonthData(for month: Month) async {
        // Optional: Background data loading for smoother experience
        // This could trigger cache warming, API calls, or other data preparation
        // Example: await historyVM.preloadData(for: month.date)
    }
}

// MARK: - Monthly Page Content
private struct MonthlyPageContent: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    let month: Month

    var body: some View {
        let summary = historyVM.getMonthSummary(for: month.date)
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(month.title)
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
            WeeklyTotalsList(month: month.date)
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
                        let maxWidth = max(0, geo.size.width)
                        let ratio = min(1, max(0, Double(bucket.totalMinutes) / Double(maxVal)))
                        let barWidth = CGFloat(ratio) * maxWidth
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DesignTokens.WhiteColors.stroke)
                                .opacity(0.2)
                            if bucket.totalMinutes > 0 && barWidth > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DesignTokens.MoonColors.accentBlue)
                                    .frame(width: barWidth, height: 8)
                            }
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
        // Compute month boundaries
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let daysRange = calendar.range(of: .day, in: .month, for: month)!
        let monthEnd = calendar.date(byAdding: .day, value: daysRange.count - 1, to: monthStart)!

        // Precomputed daily map for this month
        let days = historyVM.getDailyHistories(for: month)
        let sortedKeys = days.keys.sorted()
        guard let first = sortedKeys.first else { return [] }

        var buckets: [WeeklyBucket] = []
        var weekIndex = 0
        var currentWeekTotal = 0
        var currentWeekStart = first
        var currentWeekEnd = first

        for key in sortedKeys {
            let comp = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: key)
            let compPrev = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: currentWeekStart)
            let isSameWeek = (comp.weekOfYear == compPrev.weekOfYear) &&
                            (comp.yearForWeekOfYear == compPrev.yearForWeekOfYear)
            if !isSameWeek {
                // flush previous with month-clipped label
                let clippedStart = max(currentWeekStart, monthStart)
                let clippedEnd = min(currentWeekEnd, monthEnd)
                buckets.append(
                    WeeklyBucket(
                        index: weekIndex,
                        label: weekLabelClipped(start: clippedStart, end: clippedEnd),
                        totalMinutes: currentWeekTotal
                    )
                )
                weekIndex += 1
                currentWeekStart = key
                currentWeekEnd = key
                currentWeekTotal = 0
            } else {
                currentWeekEnd = key
            }
            currentWeekTotal += days[key]?.totalMinutes ?? 0
        }
        // flush last
        let clippedStart = max(currentWeekStart, monthStart)
        let clippedEnd = min(currentWeekEnd, monthEnd)
        buckets.append(
            WeeklyBucket(
                index: weekIndex,
                label: weekLabelClipped(start: clippedStart, end: clippedEnd),
                totalMinutes: currentWeekTotal
            )
        )
        return buckets
    }

    private func weekLabelClipped(start: Date, end: Date) -> String {
        let startDay = calendar.component(.day, from: start)
        let endDay = calendar.component(.day, from: end)
        if startDay == endDay { return "\(startDay)" }
        return "\(startDay) – \(endDay)"
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
