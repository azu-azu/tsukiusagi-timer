import SwiftUI

// MARK: - EditRecord用のヘッダービュー
struct EditRecordHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM: TimerViewModel

    // EditRecordViewから渡される編集中の値
    let editedActivity: String
    let editedTask: String
    let editedMemo: String
    let editedEnd: Date
    let isSaveDisabledExtra: Bool

    private var isCustomActivity: Bool {
        let predefinedActivities = ["Work", "Study", "Read"]
        return !predefinedActivities.contains { $0.lowercased() == editedActivity.lowercased() }
    }

    private func isActivityEmpty() -> Bool {
        return editedActivity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func shouldDisableSave() -> Bool {
        return isCustomActivity && isActivityEmpty()
    }

    var body: some View {
        VStack(spacing: 8) {
            CommonHeaderView(
                configuration: .cancelSave(
                    title: Labels.Sections.editRecord,
                    dismiss: dismiss,
                    onSave: {
                        // Persist day-level Reflection via append convenience
                        historyVM.appendToReflection(for: editedEnd, newLine: editedMemo)
                        // Clear per-record memo to avoid split-view inconsistency
                        historyVM.updateLast(
                            sessionName: editedActivity,
                            task: editedTask,
                            memo: "",
                            end: editedEnd
                        )
                        // UI即時反映（Quiet Moon / RecordedTimesView）
                        timerVM.applyEditedEndTime(editedEnd)
                        // 保存完了通知を投げて、呼び出し側で閉じる＋HUD表示などを行う
                        NotificationCenter.default.post(name: Notification.Name("TimerEditSaved"), object: nil)
                    },
                    isSaveDisabled: shouldDisableSave() || isSaveDisabledExtra
                )
            )

            // Reset button moved to bottom safe area inset (EditRecordView)
        }
        .accessibilityIdentifier("EditRecordHeaderView")
    }
}

// MARK: - プレビュー
#Preview {
    EditRecordHeaderView(
        editedActivity: "Work",
        editedTask: "Test task",
        editedMemo: "Test memo",
        editedEnd: Date(),
        isSaveDisabledExtra: false
    )
    .environmentObject(HistoryViewModel())
    .environmentObject(PreviewData.MockServices.makeTimerViewModel())
    .background(DesignTokens.CosmosColors.background)
}
