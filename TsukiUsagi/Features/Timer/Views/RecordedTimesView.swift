import SwiftUI

struct RecordedTimesView: View {
    let startTime: Date?
    let endTime: Date?
    let actualSessionMinutes: Int
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                // 上２行：中央
                VStack(spacing: 4) {
                    Text(String(format: Labels.Timer.startFormat, TimeFormatters.formatTime(date: startTime)))
                        .accessibilityIdentifier("startLabel")
                    Text(String(format: Labels.Timer.finalFormat, TimeFormatters.formatTime(date: endTime)))
                        .accessibilityIdentifier("finalLabel")
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
            }

            // 未来Finalバッジ（endTime が未来の場合に表示）
            if let end = endTime, end > Date() {
                Text(NSLocalizedString("timer_record_future", comment: "Future badge label"))
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DesignTokens.CosmosColors.cardBackground)
                    .overlay(
                        Capsule().stroke(DesignTokens.WhiteColors.stroke, lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .accessibilityIdentifier("futureFinalBadge")
            }

            // ３行目の分数表示
            Text("-- \(actualSessionMinutes) min")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
                .frame(maxWidth: 110)
                .accessibilityIdentifier("finalMinutesLabel")

            // ✏️
            HStack {
                Spacer()
                PencilButton(size: .title, action: onEdit)
                    .accessibilityLabel(NSLocalizedString(
                        "timer_record_edit_session",
                        comment: "Edit session accessibility label"
                    ))
                    .accessibilityHint(NSLocalizedString(
                        "timer_record_edit_hint",
                        comment: "Edit session accessibility hint"
                    ))
            }
            .frame(maxWidth: 110)
        }
        .padding(.top, 20)
        .background(Color.clear)
        .accessibilityElement(children: .combine)
    }
}
