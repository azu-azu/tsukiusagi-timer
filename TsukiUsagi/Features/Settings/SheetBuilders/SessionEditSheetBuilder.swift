import SwiftUI
import Foundation

/// セッション編集モーダル管理コンポーネント
///
/// 責務：
/// - Task編集とFull編集の切り替え
/// - キーボード表示状態の管理
/// - 編集完了・キャンセル処理の委譲
struct SessionEditSheetBuilder: View {
    struct TaskDraft: Identifiable, Equatable {
        let id: UUID
        var text: String

        init(id: UUID = UUID(), text: String) {
            self.id = id
            self.text = text
        }
    }

    let context: SessionEditContext
    @Binding var tempSessionName: String
    @Binding var tempTasks: [String]
    @Binding var isAnyFieldFocused: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var hasDuplicateConflict = false
    @State private var taskDrafts: [TaskDraft] = []
    @State private var focusedRowID: UUID?

    private var initialSessionName: String { context.sessionName }
    private var initialTasks: [String] { context.tasks }

    private var hasChanges: Bool {
        if context.isDefaultSession {
            return taskDrafts.map(\.text) != initialTasks
        } else {
            return tempSessionName != initialSessionName || taskDrafts.map(\.text) != initialTasks
        }
    }

    private var isSaveDisabled: Bool {
        if hasDuplicateConflict { return true }
        if !hasChanges { return true }
        if !context.isDefaultSession {
            let trimmed = tempSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return true }
        }
        return false
    }

    var body: some View {
        switch context.editMode {
        case .taskOnly:
            taskEditModal
        case .fullSession:
            fullSessionEditModal
        }
    }

    // MARK: - Private Views

    private var taskEditModal: some View {
        EditableModal(
            title: "Manage Tasks",
            onSave: {
                if !isSaveDisabled {
                    focusedRowID = nil
                    commitDrafts()
                    onSave()
                }
            },
            onCancel: {
                focusedRowID = nil
                resetDrafts()
                onCancel()
            },
            isSaveDisabled: isSaveDisabled,
            isKeyboardCloseVisible: isAnyFieldFocused,
            onKeyboardClose: handleKeyboardClose,
            focusedRowID: $focusedRowID,
            ensureVisibleMode: .bottomIfObscuredOnce,
            content: {
                TaskEditContent(
                    sessionName: context.sessionName,
                    taskDrafts: taskDrafts,
                    editingID: editingDraftID(),
                    onTasksChange: { drafts in
                        taskDrafts = drafts
                        propagateDrafts()
                        hasDuplicateConflict = containsDuplicateTasks(drafts.map(\.text))
                    },
                    isAnyFieldFocused: $isAnyFieldFocused,
                    onClearFocus: {
                        isAnyFieldFocused = false
                    },
                    onDuplicateStateChange: { conflict in
                        hasDuplicateConflict = conflict
                    },
                    onFocusChange: { id in
                        focusedRowID = id
                    }
                )
                // フォーカス行の下端をモーダルへ伝える
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: FocusedRowBottomPrefKey.self,
                            value: geo.frame(in: .global).maxY
                        )
                    }
                )
            }
        )
        .presentationDetents([.large])
        .onAppear {
            resetDrafts()
            hasDuplicateConflict = containsDuplicateTasks(tempTasks)
            if let editingID = editingDraftID() {
                focusedRowID = editingID
            } else {
                focusedRowID = nil
            }
        }
    }

    private var fullSessionEditModal: some View {
        EditableModal(
            title: "Edit Session",
            onSave: {
                if !isSaveDisabled {
                    focusedRowID = nil
                    commitDrafts()
                    onSave()
                }
            },
            onCancel: {
                focusedRowID = nil
                resetDrafts()
                onCancel()
            },
            isSaveDisabled: isSaveDisabled,
            isKeyboardCloseVisible: isAnyFieldFocused,
            onKeyboardClose: handleKeyboardClose,
            focusedRowID: $focusedRowID,
            ensureVisibleMode: .centerAggressive,
            content: {
                FullSessionEditContent(
                    sessionName: tempSessionName,
                    taskDrafts: taskDrafts,
                    onSessionNameChange: { newName in
                        tempSessionName = newName
                    },
                    onTasksChange: { drafts in
                        taskDrafts = drafts
                        propagateDrafts()
                        hasDuplicateConflict = containsDuplicateTasks(drafts.map(\.text))
                    },
                    isAnyFieldFocused: $isAnyFieldFocused,
                    onClearFocus: {
                        isAnyFieldFocused = false
                    },
                    onDuplicateStateChange: { conflict in
                        hasDuplicateConflict = conflict
                    },
                    onFocusChange: { id in
                        focusedRowID = id
                    }
                )
            }
        )
        .presentationDetents([.large])
        .onAppear {
            resetDrafts()
            hasDuplicateConflict = containsDuplicateTasks(tempTasks)
            focusedRowID = nil
        }
    }

    // MARK: - Helper Methods

    private func handleKeyboardClose() {
        isAnyFieldFocused = false
        focusedRowID = nil
        Task { @MainActor in
            Keyboard.dismiss()
        }
    }

    private func containsDuplicateTasks(_ tasks: [String]) -> Bool {
        var seen = Set<String>()
        for value in tasks {
            let key = value.tsu_taskNormalizedKey
            if key.isEmpty { continue }
            if seen.contains(key) {
                return true
            }
            seen.insert(key)
        }
        return false
    }

    private func resetDrafts() {
        let existing = taskDrafts
        taskDrafts = tempTasks.enumerated().map { index, text in
            if index < existing.count {
                return TaskDraft(id: existing[index].id, text: text)
            } else {
                return TaskDraft(text: text)
            }
        }
        propagateDrafts()
    }

    private func propagateDrafts() {
        tempTasks = taskDrafts.map(\.text)
    }

    private func commitDrafts() {
        propagateDrafts()
    }

    private func editingDraftID() -> UUID? {
        guard let index = context.taskIndex,
              index < taskDrafts.count else {
            return nil
        }
        return taskDrafts[index].id
    }
}
