import SwiftUI

struct HistoryView: View {
    // EN: shared history / JP: 履歴用の環境オブジェクト
    @EnvironmentObject var historyVM: HistoryViewModel

    /// EN: simple date–time formatter • JP: 日付＋時刻をシンプルに整形
    private func fmt(_ d: Date) -> String {
        d.formatted(.dateTime.year().month().day().hour().minute())
    }

    var body: some View {
        // EN: one row per SessionRecord / JP: セッションごとに1行
        List(historyVM.history) { rec in
            VStack(alignment: .leading, spacing: 4) {
                // 上段：日付（1回だけ）
                Text(rec.start.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // 下段：時間＋種別＋所要時間（分）
                HStack {
                    Text(rec.start.formatted(date: .omitted, time: .shortened))
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(rec.end.formatted(date: .omitted, time: .shortened))

                    Spacer(minLength: 8)

                    // 🆕 追加部分：フェーズ名＋所要時間
                    Text("Work \(durationMinutes(rec))分")
                        .font(.body)  // ← 同じfontレベルに
                        // foregroundStyleなし → デフォルト色（つまり他のテキストと揃う）
                }
                .font(.body)
            }
            .padding(.vertical, 6)
        }
    }
}

private func durationMinutes(_ rec: SessionRecord) -> Int {
    let seconds = rec.end.timeIntervalSince(rec.start)
    return max(Int(seconds) / 60, 1)  // 最低1分表示（切り捨てしすぎないため）
}

#Preview {
    NavigationStack {
        HistoryView()
            .environmentObject({
                let mock = HistoryViewModel()
                mock.add(
                    start: .init(timeIntervalSinceNow: -1800),
                    end: .init(),
                    phase: .focus,
                    label: "Work"
                )
                return mock
            }())
    }
}