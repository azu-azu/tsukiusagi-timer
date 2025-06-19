import SwiftUI

/// 粒度：日 or 月
private enum Granularity: String, CaseIterable, Identifiable {
    case day  = "Day"
    case month = "Month"
    var id: Self { self }
}

struct HistoryView: View {
    @EnvironmentObject var historyVM: HistoryViewModel

    @State private var selectedDate = Calendar.current.startOfDay(for: Date())  // 基準日
    @State private var mode: Granularity = .day // 粒度

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

                Spacer()

                Text(titleString())
                    .font(.headline)

                Spacer()

                Button { change(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .disabled(isAtLatest())
            }
            .padding(.horizontal)

            // ③ リスト（日 or 月）
            List {
                if mode == .day {
                    Section(
                        footer: Text("total \(totalMinutes())分")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    ) {
                        ForEach(records()) { rec in
                            let labelText: String = {
                                if let d = rec.detail, !d.isEmpty {
                                    return "\(rec.activity) | \(d)"
                                } else {
                                    return rec.activity
                                }
                            }()

                            HStack {
                                Text(rec.start.formatted(date: .omitted, time: .shortened))
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(rec.end.formatted(date: .omitted, time: .shortened))

                                Spacer(minLength: 8)

                                Text("\(labelText) \(durationMinutes(rec))分")
                            }
                            .font(.body)
                            .padding(.vertical, 6)
                        }
                    }
                } else {
                    Section("By Activity") {
                        ForEach(byActivity(), id: \.label) { s in rowView(s) }
                    }
                    Section("By Detail") {
                        ForEach(byDetail(), id: \.label) { s in rowView(s) }
                    }
                }
            }
            .listStyle(.plain)
        }
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

    private func byDetail() -> [LabelSummary] {
        groupAndSum { $0.detail?.isEmpty == false ? $0.detail! : "—" }
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

    @ViewBuilder
    private func rowView(_ s: LabelSummary) -> some View {
        HStack {
            Text(s.label)
            Spacer()
            Text("\(s.total)分")
        }
        .font(.body)
        .padding(.vertical, 6)
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
            return AppFormatters.displayDate.string(from: selectedDate)
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
}

// ⏱ ヘルパー：所要時間を分に変換
private func durationMinutes(_ rec: SessionRecord) -> Int {
    let sec = rec.end.timeIntervalSince(rec.start)
    return max(Int(sec) / 60, 1)
}
