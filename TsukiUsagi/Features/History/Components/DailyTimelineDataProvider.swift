//
//  DailyTimelineDataProvider.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/01/01.
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
            // Descending: latest time first
            .sorted { $0.start > $1.start }
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
        let grouped = Dictionary(grouping: records) { $0.sessionName }
        return grouped.map { sessionName, records in
            let totalSeconds = records.reduce(0) { total, rec in
                total + durationSeconds(rec)
            }
            let totalMinutes = (totalSeconds + 59) / 60  // 表示用に切り上げ
            return LabelSummary(label: sessionName, count: records.count, totalMinutes: totalMinutes)
        }.sorted { $0.totalMinutes > $1.totalMinutes }
    }

    /// タスク別集計
    func byTask(historyVM: HistoryViewModel, targetDate: Date) -> [LabelSummary] {
        let records = records(historyVM: historyVM, targetDate: targetDate)
        let grouped = Dictionary(grouping: records) { record in
            record.task?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        return grouped.compactMap { task, records in
            guard !task.isEmpty else { return nil }
            let totalSeconds = records.reduce(0) { total, rec in
                total + durationSeconds(rec)
            }
            let totalMinutes = (totalSeconds + 59) / 60  // 表示用に切り上げ
            return LabelSummary(label: task, count: records.count, totalMinutes: totalMinutes)
        }.sorted { $0.totalMinutes > $1.totalMinutes }
    }

    /// メモ付き記録を取得
    func recordsWithMemos(historyVM: HistoryViewModel, targetDate: Date) -> [SessionRecord] {
        return records(historyVM: historyVM, targetDate: targetDate)
            .filter { rec in
                !(rec.memo?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            }
    }

    func makeDaySummary(historyVM: HistoryViewModel, targetDate: Date) -> DaySummary {
        let dayRecords = records(historyVM: historyVM, targetDate: targetDate)
        guard !dayRecords.isEmpty else {
            return DaySummary(total: 0, sessionName: nil, sessionDuration: 0, tasks: [])
        }

        let totalDuration = dayRecords.reduce(0) { $0 + $1.duration }

        let grouped = Dictionary(grouping: dayRecords, by: \.sessionName)

        let dominantSessions = grouped.max { lhs, rhs in
            let lhsDuration = lhs.value.totalDuration
            let rhsDuration = rhs.value.totalDuration
            if lhsDuration == rhsDuration {
                return (lhs.value.latestEnd ?? .distantPast) < (rhs.value.latestEnd ?? .distantPast)
            }
            return lhsDuration < rhsDuration
        }?.value ?? []

        let dominantName = dominantSessions.first?.sessionName
        let sessionDuration = dominantSessions.totalDuration

        let tasks = Dictionary(grouping: dominantSessions) { ($0.task).trimmedNonEmpty ?? "" }
            .compactMap { key, sessions -> DescSlice? in
                guard !key.isEmpty else { return nil }
                let duration = sessions.reduce(0) { $0 + $1.duration }
                return DescSlice(title: key, duration: duration)
            }
            .sorted { $0.duration > $1.duration }

        return DaySummary(
            total: totalDuration,
            sessionName: dominantName,
            sessionDuration: sessionDuration,
            tasks: tasks
        )
    }

    func daySessionSummaries(historyVM: HistoryViewModel, targetDate: Date) -> [DaySessionSummary] {
        let dayRecords = records(historyVM: historyVM, targetDate: targetDate)
        return Self.makeDaySessionSummaries(for: dayRecords)
    }

    static func makeDaySessionSummaries(for records: [SessionRecord]) -> [DaySessionSummary] {
        guard !records.isEmpty else { return [] }

        let groupedBySession = Dictionary(grouping: records, by: \.sessionName)

        let summaries = groupedBySession.map { sessionName, entries -> DaySessionSummary in
            let totalDuration = entries.reduce(0) { $0 + $1.duration }

            let tasks = Dictionary(grouping: entries) {
                $0.task?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
            .compactMap { key, slice -> DescSlice? in
                guard !key.isEmpty else { return nil }
                let sliceDuration = slice.reduce(0) { $0 + $1.duration }
                return DescSlice(title: key, duration: sliceDuration)
            }
            .sorted { $0.duration > $1.duration }

            return DaySessionSummary(
                sessionName: sessionName,
                total: totalDuration,
                tasks: tasks
            )
        }

        return summaries.sorted { $0.total > $1.total }
    }
}

struct DescSlice: Hashable {
    let title: String
    let duration: TimeInterval
}

struct DaySessionSummary: Hashable {
    let sessionName: String
    let total: TimeInterval
    let tasks: [DescSlice]
}

struct DaySummary {
    let total: TimeInterval
    let sessionName: String?
    let sessionDuration: TimeInterval
    let tasks: [DescSlice]
}

// MARK: - Helpers

private extension Array where Element == SessionRecord {
    var totalDuration: TimeInterval {
        reduce(0) { $0 + $1.duration }
    }

    var latestEnd: Date? {
        map(\.end).max()
    }
}

private extension Optional where Wrapped == String {
    var trimmedNonEmpty: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}

private extension Sequence where Element: Hashable {
    func mostFrequent() -> Element? {
        Dictionary(grouping: self, by: { $0 })
            .max { lhs, rhs in lhs.value.count < rhs.value.count }?
            .key
    }
}
