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
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            }
        )
    }

    /// 時間範囲表示
    @ViewBuilder
    private func timeRangeView(_ rec: SessionRecord) -> some View {
        Text("\(rec.start.formatted(date: .omitted, time: .shortened)) - " +
             "\(rec.end.formatted(date: .omitted, time: .shortened))")
            .font(.caption)
            .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
            .frame(width: timeWidth, alignment: .leading)
    }

    /// アクティビティ情報表示
    @ViewBuilder
    private func activityInfoView(displayName: String, isDeleted: Bool) -> some View {
        Text(displayName.withSessionEmoji)
            .font(.body)
            .foregroundColor(
                isDeleted
                    ? DesignTokens.SkyToneColors.textSecondary
                    : DesignTokens.SkyToneColors.textPrimary
            )
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
            .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
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
