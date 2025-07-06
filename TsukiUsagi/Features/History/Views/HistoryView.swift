import SwiftUI

/// 粒度：日 or 月
private enum Granularity: String, CaseIterable, Identifiable {
    case day  = "Day"
    case month = "Month"
    var id: Self { self }
}

struct HistoryView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    @State private var selectedDate = Calendar.current.startOfDay(for: Date())  // 基準日
    @State private var mode: Granularity = .day // 粒度
    @State private var restoreError: String? = nil
    @State private var showRestoreAlert = false

    private let dayCardSpacing: CGFloat = 2
    private let dayModeCardHeight: CGFloat = 8

    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 12) {

            // ① 粒度切替
            Picker("Mode", selection: $mode) {
                ForEach(Granularity.allCases) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // ② ナビゲーションバー
            HStack {
                Button { change(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .foregroundColor(.moonTextSecondary)

                Spacer()

                Text(titleString())
                    .font(.headline)
                    .foregroundColor(.moonTextPrimary)

                Spacer()

                Button { change(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .foregroundColor(.moonTextSecondary)
                .disabled(isAtLatest())
            }
            .padding(.horizontal)

            // ③ リスト（日 or 月）
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
        .alert(isPresented: $showRestoreAlert) {
            Alert(title: Text("Restore Error"), message: Text(restoreError ?? ""), dismissButton: .default(Text("OK")))
        }
        .background(
            ZStack {
                Color.moonBackground.ignoresSafeArea()
                StaticStarsView(starCount: 40).allowsHitTesting(false)
                FlowingStarsView(
                    starCount: 40,
                    angle: .degrees(135),
                    durationRange: 24...40,
                    sizeRange: 2...4,
                    spawnArea: nil
                )
            }
        )
    }

    // ─────────────────────────────
    // MARK: - View Components
    // ☀️ Day MODE
    @ViewBuilder
    private func dayModeContent() -> some View {
        // Total 表示（日モード）
        totalCard(text: TimeFormatting.totalText(totalMinutes()))

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
        totalCard(text: TimeFormatting.totalText(totalMinutes()))

        // 月モードの集計表示
        activitySummarySection()
        subtitleSummarySection()
    }

    @ViewBuilder
    private func dayModeRecordsSection() -> some View {
        VStack(alignment: .leading, spacing: dayCardSpacing) {
            ForEach(records()) { rec in
                recordRow(rec)
            }
        }
    }

    @ViewBuilder
    private func recordRow(_ rec: SessionRecord) -> some View {
        let isDeleted = historyVM.isDeleted(sessionManager: sessionManager, activity: rec.activity)
        let displayName = historyVM.displayActivity(sessionManager: sessionManager, activity: rec.activity)

        HStack {
            Text(rec.start.formatted(date: .omitted, time: .shortened))
                .foregroundColor(.moonTextPrimary)
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.moonTextSecondary)
            Text(rec.end.formatted(date: .omitted, time: .shortened))
                .foregroundColor(.moonTextPrimary)
            Spacer(minLength: 8)
            Text("\(displayName) \(durationMinutes(rec)) min")
                .foregroundColor(isDeleted ? .gray : .moonTextPrimary)
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
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .frame(height: dayModeCardHeight)
        .font(.body)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.moonCardBackground.opacity(0.15))
        )
    }

    // ─────────────────────────────
    // MARK: - Record 抽出・集計
    private func records() -> [SessionRecord] {
        historyVM.history
            .filter { rec in
                switch mode {
                case .day:
                    return cal.isDate(rec.start, inSameDayAs: selectedDate)
                case .month:
                    return cal.isDate(rec.start, equalTo: selectedDate, toGranularity: .month)
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
        return grouped.map { (k, recs) in
            LabelSummary(
                label: k,
                total: recs.reduce(0) { $0 + durationMinutes($1) }
            )
        }
        .sorted { $0.total > $1.total }
    }

    private func groupAndSum<T>(_ key: (SessionRecord) -> T) -> [LabelSummary] where T: Hashable {
        let grouped = Dictionary(grouping: records(), by: key)
        return grouped.map { (k, recs) in
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
        switch mode {
        case .day:
            return DateFormatters.displayDate.string(from: selectedDate)
        case .month:
            return selectedDate.formatted(.dateTime.year().month())
        }
    }

    private func isAtLatest() -> Bool {
        switch mode {
        case .day:
            return cal.isDateInToday(selectedDate)
        case .month:
            return cal.isDate(selectedDate, equalTo: Date(), toGranularity: .month)
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

    // 共通のTotal表示用View
    private func totalCard(text: String) -> some View {
        Text(text)
            .glitter(size: 24, resourceName: "gold")
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.moonCardBackground.opacity(0.2))
            )
            .padding(.horizontal) // カード幅を少し小さくしたい時
    }

    // ─────────────────────────────
    // MARK: - View Components

    // 共通の集計セクション表示用View
    private func summarySection(title: String, summaries: [LabelSummary]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.moonTextSecondary)

            ForEach(summaries, id: \.label) { s in
                HStack {
                    Text(s.label)
                        .foregroundColor(.moonTextPrimary)
                    Spacer()
                    Text(TimeFormatting.totalText(s.total))
                        .foregroundColor(.moonTextPrimary)
                }
                .font(.body)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.moonCardBackground.opacity(0.15))
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
                    .font(.subheadline)
                    .foregroundColor(.moonTextSecondary)

                ForEach(memos, id: \.self) { memo in
                    Text(memo)
                        .font(.footnote)
                        .foregroundColor(.moonTextSecondary)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.moonCardBackground.opacity(0.15))
                        )
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
