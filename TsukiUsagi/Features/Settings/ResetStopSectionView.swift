import SwiftUI

struct ResetStopSectionView: View {
    @EnvironmentObject private var timerVM: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    private let cardCornerRadius: CGFloat = 8

    var body: some View {
        section(title: "", isCompact: false) {
            VStack(spacing: 14) {
                Button {
                    timerVM.resetTimer()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        // 🛑 Reset
                        Image(systemName: "arrow.uturn.backward")
                        Text(timerVM.isWorkSession
                            ? "Reset Timer (No Save)"
                            : "Reset Timer (already saved)"
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tint(.red.opacity(0.8))

                // 🛑 Stop
                if timerVM.isWorkSession && timerVM.startTime != nil {
                    Button {
                        Task {
                            await timerVM.forceFinishWorkSession()
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "forward.end")
                            Text("Stop (Save)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .tint(.blue)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.end")
                            .foregroundColor(.gray.opacity(0.6))
                        Text("Stop (Save)")
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        isCompact: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: isCompact
                ? DesignTokens.Spacing.extraSmall
                : DesignTokens.Spacing.small
        ) {
            if !title.isEmpty {
                Text(title)
                    .font(DesignTokens.Fonts.sectionTitle)
                    .foregroundColor(DesignTokens.Colors.moonTextSecondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(isCompact
                ? EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                : EdgeInsets())
            .padding(isCompact ? .init() : .all)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(DesignTokens.Colors.moonCardBG)
            )
        }
    }
}

#if DEBUG
struct ResetStopSectionView_Previews: PreviewProvider {
    static var previews: some View {
        ResetStopSectionView()
            .environmentObject(TimerViewModel(historyVM: HistoryViewModel()))
    }
}
#endif