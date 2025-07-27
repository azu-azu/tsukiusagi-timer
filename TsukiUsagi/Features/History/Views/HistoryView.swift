import SwiftUI
import Foundation

/// 表示モード
private enum ViewMode: String, CaseIterable, Identifiable {
    case calendar = "Calendar"
    case timeline = "Timeline"
    var id: Self { self }
}

/// 粒度：日 or 月（タイムラインモード用）
private enum Granularity: String, CaseIterable, Identifiable {
    case day = "Day"
    case month = "Month"
    var id: Self { self }
}

struct HistoryView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    @State private var viewMode: ViewMode = .calendar // デフォルトをカレンダーに
    @State private var selectedDate = Calendar.current.startOfDay(for: Date()) // 基準日
    @State private var mode: Granularity = .day // 粒度
    @State private var restoreError: String?
    @State private var showRestoreAlert = false

    private let summaryCardHeight: CGFloat = 50
    private let dayModeCardHeight: CGFloat = 40
    private let dayModeCardSpacing: CGFloat = 2
    private let timeWidth: CGFloat = 100 // 右端のtime
    private let arrowWidth: CGFloat = 34

    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 12) {
            // ① ビューモード切替
            Picker("View Mode", selection: $viewMode) {
                ForEach(ViewMode.allCases) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // ② 条件分岐表示
            switch viewMode {
            case .calendar:
                CalendarHistoryView()
            case .timeline:
                timelineContent()
            }
        }
        .alert(isPresented: $showRestoreAlert) {
            Alert(title: Text("Restore Error"), message: Text(restoreError ?? ""), dismissButton: .default(Text("OK")))
        }
        .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
    }

    // MARK: - Timeline Content

    @ViewBuilder
    private func timelineContent() -> some View {
        VStack(spacing: 12) {
            // 粒度切替（タイムラインモードのみ）
            Picker("Mode", selection: $mode) {
                ForEach(Granularity.allCases) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // ナビゲーションバー
            HStack {
                Button { change(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

                Spacer()

                Text(titleString())
                    .font(DesignTokens.Fonts.labelBold)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                Spacer()

                Button { change(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .disabled(isAtLatest())
            }
            .padding(.horizontal)

            // リスト（日 or 月）
            ScrollView {
                LazyVStack(spacing: 16) {
                    if mode == .day {
                        dayModeContent()
                    } else {
                        monthModeContent()
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // ─────────────────────────────

    // MARK: - View Components

    // ☀️ Day MODE
    @ViewBuilder
    private func dayModeContent() -> some View {
        // Total 表示（日モード）
        TotalCard(text: TimeFormatters.totalText(totalMinutes()))

        // 日モードのレコード表示
        dayModeRecordsSection()

        // 日モードの集計表示（レコードが複数ある場合のみ）
        if records().count > 1 {
            activitySummarySection()
            subtitleSummarySection()
        }

        // メモ部分
        memoSection()
    }

    // 🌝 Month MODE
    @ViewBuilder
    private func monthModeContent() -> some View {
        // Total 表示（月モード）
        TotalCard(text: TimeFormatters.totalText(totalMinutes()))

        // 月モードの集計表示
        activitySummarySection()
        subtitleSummarySection()
    }

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

    // ─────────────────────────────

    // MARK: - Record 抽出・集計

    private func records() -> [SessionRecord] {
        // fixedDate があればそれを使用、なければ selectedDate を使用
        let targetDate = historyVM.fixedDate ?? selectedDate

        return historyVM.history
            .filter { rec in
                switch mode {
                case .day:
                    return cal.isDate(rec.start, inSameDayAs: targetDate)
                case .month:
                    return cal.isDate(rec.start, equalTo: targetDate, toGranularity: .month)
                }
            }
            .sorted { $0.start < $1.start }
    }

    private func totalMinutes() -> Int {
        records().reduce(0) { $0 + durationMinutes($1) }
    }

    // ─────────────────────────────

    // MARK: - 集計構造

    private struct LabelSummary {
        let label: String
        let total: Int
    }

    private func byActivity() -> [LabelSummary] {
        groupAndSum(\.activity)
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

    private func groupAndSum<T>(_ key: (SessionRecord) -> T) -> [LabelSummary] where T: Hashable {
        let grouped = Dictionary(grouping: records(), by: key)
        return grouped.map { k, recs in
            LabelSummary(
                label: String(describing: k),
                total: recs.reduce(0) { $0 + durationMinutes($1) }
            )
        }
        .sorted { $0.total > $1.total }
    }

    // ─────────────────────────────

    // MARK: - ナビゲーション

    private func change(by offset: Int) {
        let component: Calendar.Component = (mode == .day) ? .day : .month
        if let newDate = cal.date(byAdding: component, value: offset, to: selectedDate) {
            selectedDate = startOfPeriod(for: newDate)
        }
    }

    private func titleString() -> String {
        let targetDate = historyVM.fixedDate ?? selectedDate
        switch mode {
        case .day:
            return DateFormatters.displayDate.string(from: targetDate)
        case .month:
            return targetDate.formatted(.dateTime.year().month())
        }
    }

    private func isAtLatest() -> Bool {
        let targetDate = historyVM.fixedDate ?? selectedDate
        switch mode {
        case .day:
            return cal.isDateInToday(targetDate)
        case .month:
            return cal.isDate(targetDate, equalTo: Date(), toGranularity: .month)
        }
    }

    private func startOfPeriod(for date: Date) -> Date {
        switch mode {
        case .day:
            return cal.startOfDay(for: date)
        case .month:
            return cal.date(from: cal.dateComponents([.year, .month], from: date))!
        }
    }

    // ─────────────────────────────

    // MARK: - View Components

    // 共通の集計セクション表示用View
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
                .summaryCardStyle(
                    height: summaryCardHeight
                )
            }
        }
        .padding(.top, 16)
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

// ⏱ ヘルパー：所要時間を分に変換
private func durationMinutes(_ rec: SessionRecord) -> Int {
    let sec = rec.end.timeIntervalSince(rec.start)
    return max(Int(sec) / 60, 1)
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
