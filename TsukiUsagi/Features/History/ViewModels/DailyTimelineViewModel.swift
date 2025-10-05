//
//  DailyTimelineViewModel.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/01/01.
//

import SwiftUI
import Foundation

/// DailyTimelineViewの状態管理とビジネスロジックを担当するViewModel
@MainActor
final class DailyTimelineViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var restoreError: String?
    @Published var showRestoreAlert = false
    @Published var selectedRecordForMemoEdit: SessionRecord?

    // MARK: - Dependencies

    private let targetDate: Date
    private let calendar = Calendar.current

    // MARK: - Initialization

    init(targetDate: Date) {
        self.targetDate = targetDate
    }

    // MARK: - Public Methods

    /// レコード一覧を取得
    func records(historyVM: HistoryViewModel) -> [SessionRecord] {
        return historyVM.history.filter { calendar.isDate($0.start, inSameDayAs: targetDate) }
    }

    /// 総時間（秒）を計算
    func totalSeconds(historyVM: HistoryViewModel) -> Int {
        return records(historyVM: historyVM).reduce(0) { $0 + durationSeconds($1) }
    }

    /// レコードの時間（秒）を計算
    func durationSeconds(_ rec: SessionRecord) -> Int {
        return Int(rec.end.timeIntervalSince(rec.start))
    }

    /// アクティビティ別集計
    func byActivity(historyVM: HistoryViewModel) -> [LabelSummary] {
        let records = records(historyVM: historyVM)
        let grouped = Dictionary(grouping: records) { $0.activity }
        return grouped.map { activity, records in
            let totalSeconds = records.reduce(0) { $0 + durationSeconds($1) }
            let totalMinutes = (totalSeconds + 59) / 60  // 表示用に切り上げ
            return LabelSummary(label: activity, count: records.count, totalMinutes: totalMinutes)
        }.sorted { $0.totalMinutes > $1.totalMinutes }
    }

    /// サブタイトル別集計
    func bySubtitle(historyVM: HistoryViewModel) -> [LabelSummary] {
        let records = records(historyVM: historyVM)
        let grouped = Dictionary(grouping: records) { $0.subtitle ?? "" }
        return grouped.compactMap { subtitle, records in
            guard !subtitle.isEmpty else { return nil }
            let totalSeconds = records.reduce(0) { $0 + durationSeconds($1) }
            let totalMinutes = (totalSeconds + 59) / 60  // 表示用に切り上げ
            return LabelSummary(label: subtitle, count: records.count, totalMinutes: totalMinutes)
        }.sorted { $0.totalMinutes > $1.totalMinutes }
    }

    /// メモ付きレコード一覧
    func recordsWithMemos(historyVM: HistoryViewModel) -> [SessionRecord] {
        return records(historyVM: historyVM).filter { !($0.memo?.isEmpty ?? true) }
    }

    /// レコード復元
    func restoreRecord(_ record: SessionRecord, historyVM: HistoryViewModel, sessionManager: SessionManager) {
        do {
            try historyVM.restore(record: record, sessionManager: sessionManager)
            // 復元成功時の処理
        } catch {
            restoreError = error.localizedDescription
            showRestoreAlert = true
        }
    }

    /// メモ編集用レコード選択
    func selectRecordForMemoEdit(_ record: SessionRecord) {
        selectedRecordForMemoEdit = record
    }

    /// アラート表示
    func showAlert(error: String) {
        restoreError = error
        showRestoreAlert = true
    }
}
