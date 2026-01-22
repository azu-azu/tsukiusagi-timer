import SwiftUI

// MARK: - Settings用のヘッダービュー
struct SettingsHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var timerVM: TimerViewModel
    @AppStorage("activityLabel") private var activityLabel: String = "Work"

    var onDismiss: (() -> Void)?

    private var isCustomActivity: Bool {
        !["Work", "Study", "Read"].contains(activityLabel)
    }

    private func isActivityEmpty() -> Bool {
        return activityLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func shouldDisableDone() -> Bool {
        return isCustomActivity && isActivityEmpty()
    }

    var body: some View {
        CommonHeaderView(
            configuration: .closeDone(
                title: "Settings",
                dismiss: dismiss,
                customClose: onDismiss,
                onDone: {
                    timerVM.refreshAfterSettingsChange()
                    onDismiss?() ?? dismiss()
                },
                isDoneDisabled: shouldDisableDone()
            )
        )
    }
}

// MARK: - プレビュー
#Preview {
    SettingsHeaderView()
        .environmentObject(PreviewData.MockServices.makeTimerViewModel())
        .background(DesignTokens.CosmosColors.background)
}
