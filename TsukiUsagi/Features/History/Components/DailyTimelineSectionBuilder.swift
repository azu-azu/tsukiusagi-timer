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
        onRestore: @escaping (SessionRecord) -> Void
    ) -> some View {
        LazyVStack(spacing: dayModeCardSpacing) {
            ForEach(records, id: \.id) { rec in
                recordRow(rec, onRestore: onRestore)
            }
        }
    }

    /// アクティビティ集計セクション
    @ViewBuilder
    func activitySummarySection(summaries: [LabelSummary]) -> some View {
        summarySection(title: "Session Summary", summaries: summaries, isTask: false)
    }

    /// タスク集計セクション
    @ViewBuilder
    func taskSummarySection(summaries: [LabelSummary]) -> some View {
        summarySection(title: "Task Summary", summaries: summaries, isTask: true)
    }
}

// MARK: - Row / Time / Info
extension DailyTimelineSectionBuilder {
    /// レコード行
    @ViewBuilder
    private func recordRow(
        _ rec: SessionRecord,
        onRestore: @escaping (SessionRecord) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            timeRangeView(rec)
            activityInfoView(displayName: rec.sessionName, isDeleted: false)
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
    private func activityInfoView(displayName: String, isDeleted: Bool) -> some View {
        Text(displayName.withSessionEmoji)
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

// MARK: - Summary
extension DailyTimelineSectionBuilder {
    /// 集計セクション共通
    @ViewBuilder
    private func summarySection(title: String, summaries: [LabelSummary], isTask: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            LazyVStack(spacing: 4) {
                ForEach(summaries, id: \LabelSummary.label) { summary in
                    HStack {
                        Text(isTask ? summary.label.withTaskEmoji : summary.label.withSessionEmoji)
                            .font(.body)
                            .foregroundColor(DesignTokens.MoonColors.textPrimary)
                        Spacer()
                        // total と同じ h min s 形式に合わせる（分→秒に変換して表示）
                        Text(TimeFormatters.totalTextWithSeconds(summary.totalMinutes * 60))
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
