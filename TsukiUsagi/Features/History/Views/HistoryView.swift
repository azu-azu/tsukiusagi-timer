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
                        // Total 表示（日モード）
                        totalCard(text: TimeFormatting.totalText(totalMinutes()))

                        // 日モードのレコード表示
                        VStack(alignment: .leading, spacing: 8) {
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
                                        .foregroundColor(.moonTextPrimary)
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundColor(.moonTextSecondary)
                                    Text(rec.end.formatted(date: .omitted, time: .shortened))
                                        .foregroundColor(.moonTextPrimary)

                                    Spacer(minLength: 8)

                                    Text("\(labelText) \(durationMinutes(rec)) min")
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

                        // メモ部分
                        let memos = records()
                            .compactMap { $0.memo?.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        if !memos.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("📝 Memos")
                                    .font(.subheadline)
                                    .foregroundColor(.moonTextSecondary)
                                    .padding(.bottom, 4)

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
                    } else {
                        // Total 表示（月モード）
                        totalCard(text: TimeFormatting.totalText(totalMinutes()))

                        // 月モードの集計表示
                        VStack(alignment: .leading, spacing: 8) {
                            Text("By Activity")
                                .font(.subheadline)
                                .foregroundColor(.moonTextSecondary)
                                .padding(.bottom, 4)

                            ForEach(byActivity(), id: \.label) { s in
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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("By Detail")
                                .font(.subheadline)
                                .foregroundColor(.moonTextSecondary)
                                .padding(.bottom, 4)

                            ForEach(byDetail(), id: \.label) { s in
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
                }
                .padding(.horizontal)
            }
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
}

// ⏱ ヘルパー：所要時間を分に変換
private func durationMinutes(_ rec: SessionRecord) -> Int {
    let sec = rec.end.timeIntervalSince(rec.start)
    return max(Int(sec) / 60, 1)
}
