//
//  DailyTimelineSectionBuilder.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/01/01.
//

import SwiftUI

/// DailyTimelineViewのセクションUI構築を担当するBuilder
struct DailyTimelineSectionBuilder {

    // MARK: - Constants

    private let dayModeCardHeight: CGFloat = 40
    private let dayModeCardSpacing: CGFloat = 2
    private let timeWidth: CGFloat = 100
    private let summaryCardHeight: CGFloat = 50

    // MARK: - Section Builders

    /// レコード一覧セクション
    @ViewBuilder
    func dayModeRecordsSection(
        records: [SessionRecord],
        onRestore: @escaping (SessionRecord) -> Void,
        onMemoEdit: @escaping (SessionRecord) -> Void
    ) -> some View {
        LazyVStack(spacing: dayModeCardSpacing) {
            ForEach(records, id: \.id) { rec in
                recordRow(rec, onRestore: onRestore, onMemoEdit: onMemoEdit)
            }
        }
    }

    /// アクティビティ集計セクション
    @ViewBuilder
    func activitySummarySection(summaries: [LabelSummary]) -> some View {
        summarySection(title: "Activity Summary", summaries: summaries)
    }

    /// サブタイトル集計セクション
    @ViewBuilder
    func subtitleSummarySection(summaries: [LabelSummary]) -> some View {
        summarySection(title: "Subtitle Summary", summaries: summaries)
    }

    /// メモセクション
    @ViewBuilder
    func memoSection(
        records: [SessionRecord],
        onMemoEdit: @escaping (SessionRecord) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            memoSectionHeader()
            memoItemsList(records: records, onMemoEdit: onMemoEdit)
        }
    }
}

// MARK: - Row / Time / Info
extension DailyTimelineSectionBuilder {
    /// レコード行
    @ViewBuilder
    private func recordRow(
        _ rec: SessionRecord,
        onRestore: @escaping (SessionRecord) -> Void,
        onMemoEdit: @escaping (SessionRecord) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            timeRangeView(rec)
            activityInfoView(displayName: rec.activity, rec: rec, isDeleted: false)
            Spacer()
            durationView(rec)
        }
        .frame(height: dayModeCardHeight)
        .padding(.horizontal, 12)
        .background(DesignTokens.CosmosColors.cardBackground)
        .cornerRadius(8)
    }

    /// 時間範囲表示
    @ViewBuilder
    private func timeRangeView(_ rec: SessionRecord) -> some View {
        Text("\(rec.start.formatted(date: .omitted, time: .shortened)) - " +
             "\(rec.end.formatted(date: .omitted, time: .shortened))")
            .font(.caption)
            .foregroundColor(DesignTokens.MoonColors.textSecondary)
            .frame(width: timeWidth, alignment: .leading)
    }

    /// アクティビティ情報表示
    @ViewBuilder
    private func activityInfoView(displayName: String, rec: SessionRecord, isDeleted: Bool) -> some View {
        Text(displayName)
            .font(.body)
            .foregroundColor(isDeleted ? DesignTokens.MoonColors.textSecondary : DesignTokens.MoonColors.textPrimary)
            .strikethrough(isDeleted)
    }

    /// 時間表示
    @ViewBuilder
    private func durationView(_ rec: SessionRecord) -> some View {
        let totalSeconds = Int(rec.end.timeIntervalSince(rec.start))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        Text(durationText(minutes: minutes, seconds: seconds))
            .font(.body)
            .foregroundColor(DesignTokens.MoonColors.textSecondary)
    }

    private func durationText(minutes: Int, seconds: Int) -> String {
        if minutes > 0 && seconds > 0 {
            return "\(minutes) min \(seconds) s"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "\(seconds) s"
        }
    }
}

// MARK: - Actions
extension DailyTimelineSectionBuilder {
    /// アクションボタン表示
    @ViewBuilder
    private func actionButtonView(
        rec: SessionRecord,
        isDeleted: Bool,
        onRestore: @escaping (SessionRecord) -> Void,
        onMemoEdit: @escaping (SessionRecord) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            if isDeleted {
                restoreButton(rec: rec, onRestore: onRestore)
            } else {
                memoButton(rec: rec, onMemoEdit: onMemoEdit)
            }
        }
    }

    /// 復元ボタン
    @ViewBuilder
    private func restoreButton(rec: SessionRecord, onRestore: @escaping (SessionRecord) -> Void) -> some View {
        Button(
            action: { onRestore(rec) },
            label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
            }
        )
    }

    /// メモボタン
    @ViewBuilder
    private func memoButton(rec: SessionRecord, onMemoEdit: @escaping (SessionRecord) -> Void) -> some View {
        Button(
            action: { onMemoEdit(rec) },
            label: {
                Image(systemName: (rec.memo?.isEmpty ?? true) ? "note.text" : "note.text.badge.plus")
                    .foregroundColor((rec.memo?.isEmpty ?? true) ? .gray : .blue)
            }
        )
    }
}

// MARK: - Summary
extension DailyTimelineSectionBuilder {
    /// 集計セクション共通
    @ViewBuilder
    private func summarySection(title: String, summaries: [LabelSummary]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            LazyVStack(spacing: 4) {
                ForEach(summaries, id: \LabelSummary.label) { summary in
                    HStack {
                        Text(summary.label)
                            .font(.body)
                            .foregroundColor(DesignTokens.MoonColors.textPrimary)
                        Spacer()
                        Text("\(summary.totalMinutes) min")
                            .font(.caption)
                            .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    }
                    .frame(height: summaryCardHeight)
                    .padding(.horizontal, 12)
                    .background(DesignTokens.CosmosColors.cardBackground)
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Memo
extension DailyTimelineSectionBuilder {
    /// メモセクションヘッダー
    @ViewBuilder
    private func memoSectionHeader() -> some View {
        Text("Reflect")
            .font(.caption)
            .foregroundColor(DesignTokens.MoonColors.textSecondary)
    }

    /// メモアイテム一覧
    @ViewBuilder
    private func memoItemsList(
        records: [SessionRecord],
        onMemoEdit: @escaping (SessionRecord) -> Void
    ) -> some View {
        LazyVStack(spacing: 4) {
            if records.isEmpty {
                // メモが登録されていない場合の新規追加ボタン
                addMemoButton(onMemoEdit: onMemoEdit)
            } else {
                // 既存のメモアイテム
                ForEach(records, id: \.id) { record in
                    memoItemButton(record: record, onMemoEdit: onMemoEdit)
                }
            }
        }
    }

    /// メモアイテムボタン
    @ViewBuilder
    private func memoItemButton(
        record: SessionRecord,
        onMemoEdit: @escaping (SessionRecord) -> Void
    ) -> some View {
        memoItemContent(record: record, onMemoEdit: onMemoEdit)
    }

    /// メモアイテム内容
    @ViewBuilder
    private func memoItemContent(record: SessionRecord, onMemoEdit: @escaping (SessionRecord) -> Void) -> some View {
        HStack(spacing: 8) {
            memoTextContent(record: record)
            Spacer()
            memoEditButton(record: record, onMemoEdit: onMemoEdit)
        }
        .frame(height: summaryCardHeight)
        .padding(.horizontal, 12)
        .background(DesignTokens.CosmosColors.cardBackground)
        .cornerRadius(8)
    }

    /// メモテキスト内容
    @ViewBuilder
    private func memoTextContent(record: SessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(record.activity)
                .font(.body)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
            Text(record.memo ?? "")
                .font(.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .lineLimit(2)
        }
    }

    /// メモ編集ボタン
    @ViewBuilder
    private func memoEditButton(record: SessionRecord, onMemoEdit: @escaping (SessionRecord) -> Void) -> some View {
        Button(
            action: {
                onMemoEdit(record)
            },
            label: {
                Image(systemName: "pencil")
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    .font(.title2)
            }
        )
        .buttonStyle(PlainButtonStyle())
    }

    /// 新規メモ追加ボタン（メモが登録されていない場合）
    @ViewBuilder
    private func addMemoButton(onMemoEdit: @escaping (SessionRecord) -> Void) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Add reflection")
                    .font(.body)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                Text("Tap the pencil to add your thoughts")
                    .font(.caption)
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
            }
            Spacer()
            Button(
                action: {
                    // ダミーのSessionRecordを作成して新規追加をトリガー
                    let dummyRecord = SessionRecord(
                        id: UUID().uuidString,
                        start: Date(),
                        end: Date(),
                        phase: .focus,
                        activity: "New Reflection",
                        subtitle: "",
                        memo: ""
                    )
                    onMemoEdit(dummyRecord)
                },
                label: {
                    Image(systemName: "pencil")
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                        .font(.title2)
                }
            )
            .buttonStyle(PlainButtonStyle())
        }
        .frame(height: summaryCardHeight)
        .padding(.horizontal, 12)
        .background(DesignTokens.CosmosColors.cardBackground)
        .cornerRadius(8)
        .onTapGesture {
            // ダミーのSessionRecordを作成して新規追加をトリガー
            let dummyRecord = SessionRecord(
                id: UUID().uuidString,
                start: Date(),
                end: Date(),
                phase: .focus,
                activity: "New Reflection",
                subtitle: "",
                memo: ""
            )
            onMemoEdit(dummyRecord)
        }
    }
}
