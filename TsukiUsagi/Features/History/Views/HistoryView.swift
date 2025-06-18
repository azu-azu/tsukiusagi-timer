import SwiftUI

/// 粒度：日 or 月
private enum Granularity: String, CaseIterable, Identifiable {
    case day  = "Day"
    case month = "Month"
    var id: Self { self }
}

struct HistoryView: View {
    @EnvironmentObject var historyVM: HistoryViewModel

    @State private var selectedDate = Calendar.current.startOfDay(for: Date()) // 基準日
    @State private var mode: Granularity = .day                                // 粒度

    private let cal = Calendar.current

    // ─────────────────────────────
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
                Section(
                    footer: Text("total Work \(totalMinutes())分")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                ) {
                    if mode == .day {
                        // 日別はこれまで通り
                        ForEach(records()) { rec in
                            HStack {
                                Text(rec.start.formatted(date: .omitted, time: .shortened))
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(rec.end.formatted(date: .omitted, time: .shortened))

                                Spacer(minLength: 8)

                                Text("\(rec.label) \(durationMinutes(rec))分")
                            }
                            .font(.body)
                            .padding(.vertical, 6)
                        }
                    } else {
                        // 月別：ラベルごとの合計を表示
                        ForEach(groupedSummary(), id: \.label) { summary in
                            HStack {
                                Text(summary.label)
                                Spacer()
                                Text("\(summary.total)分")
                            }
                            .font(.body)
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    // ─────────────────────────────
    // MARK: - 取り出し & 集計
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
    // MARK: - ナビゲーション
    private func change(by offset: Int) {
        let component: Calendar.Component = (mode == .day) ? .day : .month
        if let newDate = cal.date(byAdding: component, value: offset, to: selectedDate) {
            selectedDate = startOfPeriod(for: newDate)
        }
    }

    private func titleString() -> String {
        switch mode {
        // 日別
        case .day:
            return AppFormatters.displayDate.string(from: selectedDate)
        // 月別
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
    // ラベルごとの合計値を算出
    private struct LabelSummary {
        let label: String
        let total: Int
    }

    private func groupedSummary() -> [LabelSummary] {
        let items = records()
        let grouped = Dictionary(grouping: items, by: { $0.label })

        return grouped.map { (label, recs) in
            let sum = recs.reduce(0) { $0 + durationMinutes($1) }
            return LabelSummary(label: label, total: sum)
        }
        .sorted { $0.label < $1.label }
    }
}

// 既存ヘルパー
private func durationMinutes(_ rec: SessionRecord) -> Int {
    let sec = rec.end.timeIntervalSince(rec.start)
    return max(Int(sec) / 60, 1)
}

