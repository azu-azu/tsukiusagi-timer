import SwiftUI

struct ResetStopSectionView: View {
    @EnvironmentObject private var timerVM: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    private let cardCornerRadius: CGFloat = 8

    private var resetTitle: String {
        timerVM.isWorkSession
            ? "Reset Timer (No Save)"
            : "Reset Timer (already saved)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
                // 🛑 Reset
                if timerVM.canResetNow {
                    Button {
                        Task { @MainActor in
                            await timerVM.resetTimer(to: timerVM.workMinutes * 60)
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.uturn.backward")
                            Text(resetTitle)
                                .font(DesignTokens.Fonts.label)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .tint(DesignTokens.MoonColors.errorBackground)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward")
                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                        Text(resetTitle)
                            .font(DesignTokens.Fonts.label)
                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 区切り線
                Divider()

                // 🛑 Stop
                if timerVM.canStopNow {
                    Button {
                        Task { @MainActor in
                            await timerVM.forceFinish()
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "forward.end")
                            Text("Stop (Save)")
                                .font(DesignTokens.Fonts.label)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .tint(DesignTokens.MoonColors.accentBlue)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.end")
                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                        Text("Stop (Save)")
                            .font(DesignTokens.Fonts.label)
                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(DesignTokens.CosmosColors.cardBackground)
        )
        .accessibilityIdentifier("ResetStopSectionView")
    }

}

#if DEBUG
#Preview {
    let vm = PreviewData.MockServices.makeTimerViewModel()
    vm._setPreviewState(startTime: Date(), isWorkSession: true, isRunning: true)
    return ResetStopSectionView()
        .environmentObject(vm)
}
#endif
