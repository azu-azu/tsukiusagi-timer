//
//  DailyTimelineDataProvider.swift
//  TsukiUsagi
//
//  Created by Kazumi on 2025/01/01.
//

import Foundation

/// DailyTimelineViewのデータ提供を担当するプロバイダー
@MainActor
struct DailyTimelineDataProvider {

    // MARK: - Data Methods

    /// 記録を取得
    func records(historyVM: HistoryViewModel, targetDate: Date) -> [SessionRecord] {
        return historyVM.history
            .filter { rec in
                Calendar.current.isDate(rec.start, inSameDayAs: targetDate)
            }
            .sorted { $0.start < $1.start }
    }

    /// 総時間（秒）を計算
    func totalSeconds(historyVM: HistoryViewModel, targetDate: Date) -> Int {
        return records(historyVM: historyVM, targetDate: targetDate)
            .reduce(0) { total, rec in
                total + Int(rec.end.timeIntervalSince(rec.start))
            }
    }

    /// 記録の時間（秒）を計算
    func durationSeconds(_ rec: SessionRecord) -> Int {
        return Int(rec.end.timeIntervalSince(rec.start))
    }

    /// アクティビティ別集計
    func byActivity(historyVM: HistoryViewModel, targetDate: Date) -> [LabelSummary] {
        let records = records(historyVM: historyVM, targetDate: targetDate)
        let grouped = Dictionary(grouping: records) { $0.activity }
        return grouped.map { activity, records in
            let totalSeconds = records.reduce(0) { total, rec in
                total + durationSeconds(rec)
            }
            let totalMinutes = (totalSeconds + 59) / 60  // 表示用に切り上げ
            return LabelSummary(label: activity, count: records.count, totalMinutes: totalMinutes)
        }.sorted { $0.totalMinutes > $1.totalMinutes }
    }

    /// サブタイトル別集計
    func bySubtitle(historyVM: HistoryViewModel, targetDate: Date) -> [LabelSummary] {
        let records = records(historyVM: historyVM, targetDate: targetDate)
        let grouped = Dictionary(grouping: records) { $0.subtitle ?? "" }
        return grouped.compactMap { subtitle, records in
            guard !subtitle.isEmpty else { return nil }
            let totalSeconds = records.reduce(0) { total, rec in
                total + durationSeconds(rec)
            }
            let totalMinutes = (totalSeconds + 59) / 60  // 表示用に切り上げ
            return LabelSummary(label: subtitle, count: records.count, totalMinutes: totalMinutes)
        }.sorted { $0.totalMinutes > $1.totalMinutes }
    }

    /// メモ付き記録を取得
    func recordsWithMemos(historyVM: HistoryViewModel, targetDate: Date) -> [SessionRecord] {
        return records(historyVM: historyVM, targetDate: targetDate)
            .filter { rec in
                !(rec.memo?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            }
    }
}
