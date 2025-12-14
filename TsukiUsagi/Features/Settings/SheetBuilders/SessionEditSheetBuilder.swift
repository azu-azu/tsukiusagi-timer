import SwiftUI
import Foundation

/// セッション編集モーダル管理コンポーネント
///
/// 責務：
/// - Task編集とFull編集の切り替え
/// - キーボード表示状態の管理
/// - 編集完了・キャンセル処理の委譲
/// - Reflection方式の入力バー管理
struct SessionEditSheetBuilder: View {
    struct TaskDraft: Identifiable, Equatable {
        let id: UUID
        var text: String

        init(id: UUID = UUID(), text: String) {
            self.id = id
            self.text = text
        }
    }

    /// 編集中のフィールドを表す
    enum EditingField: Equatable {
        case none
        case sessionName
        case task(id: UUID)
        case newTask
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
    @State private var editingField: EditingField = .none
    @State private var newTaskText: String = ""
    @State private var showLargeEditor = false
    @FocusState private var isInputBarFocused: Bool

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

    // MARK: - Input Bar Bindings

    private var currentEditingTextBinding: Binding<String> {
        switch editingField {
        case .none:
            return .constant("")
        case .sessionName:
            return $tempSessionName
        case .task(let id):
            return Binding(
                get: { taskDrafts.first(where: { $0.id == id })?.text ?? "" },
                set: { newValue in
                    if let index = taskDrafts.firstIndex(where: { $0.id == id }) {
                        taskDrafts[index].text = newValue
                        propagateDrafts()
                        hasDuplicateConflict = containsDuplicateTasks(taskDrafts.map(\.text))
                    }
                }
            )
        case .newTask:
            return $newTaskText
        }
    }

    private var currentPlaceholder: LocalizedStringKey {
        switch editingField {
        case .none:
            return ""
        case .sessionName:
            return LocalizedStringKey("enter_session_name_placeholder")
        case .task, .newTask:
            return LocalizedStringKey("task_placeholder")
        }
    }

    private var currentEditorTitle: String {
        switch editingField {
        case .none:
            return ""
        case .sessionName:
            return Labels.InfoRow.sessionName
        case .task, .newTask:
            return Labels.InfoRow.tasksOptional
        }
    }

    private func closeInputBar() {
        // 新規タスク追加時は空でなければ保存
        if case .newTask = editingField {
            let trimmed = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let newDraft = TaskDraft(text: trimmed)
                taskDrafts.append(newDraft)
                propagateDrafts()
                hasDuplicateConflict = containsDuplicateTasks(taskDrafts.map(\.text))
            }
            newTaskText = ""
        }
        isInputBarFocused = false
        editingField = .none
        isAnyFieldFocused = false
        Keyboard.dismiss()
    }

    @ViewBuilder
    private func inputBarView() -> some View {
        if editingField != .none {
            BottomInputBar(
                text: currentEditingTextBinding,
                isFocused: $isInputBarFocused,
                placeholder: currentPlaceholder,
                onExpand: {
                    showLargeEditor = true
                }
            )
        }
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
                    closeInputBar()
                    commitDrafts()
                    onSave()
                }
            },
            onCancel: {
                closeInputBar()
                resetDrafts()
                onCancel()
            },
            isSaveDisabled: isSaveDisabled,
            isKeyboardCloseVisible: editingField != .none,
            onKeyboardClose: closeInputBar,
            focusedRowID: $focusedRowID,
            ensureVisibleMode: .none,
            bottomBar: { inputBarView() },
            content: {
                TaskEditContent(
                    sessionName: context.sessionName,
                    taskDrafts: taskDrafts,
                    duplicateIDs: duplicateTaskIDs,
                    editingTaskID: editingTaskID,
                    onTaskTap: { id in
                        editingField = .task(id: id)
                        activateInputBar()
                    },
                    onNewTaskTap: {
                        newTaskText = ""
                        editingField = .newTask
                        activateInputBar()
                    },
                    onTaskDelete: { id in
                        removeTask(with: id)
                    },
                    isAddingNewTask: editingField == .newTask
                )
            }
        )
        .presentationDetents([.large])
        .sheet(isPresented: $showLargeEditor) {
            LargeTextEditorSheet(
                text: currentEditingTextBinding,
                title: currentEditorTitle,
                placeholder: currentPlaceholder,
                onClose: { showLargeEditor = false }
            )
        }
        .onAppear {
            resetDrafts()
            hasDuplicateConflict = containsDuplicateTasks(tempTasks)
            // タップするまで入力バーは表示しない
        }
        .onChange(of: editingField) { _, newValue in
            if newValue != .none {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isInputBarFocused = true
                }
            }
        }
    }

    /// 現在編集中のタスクID（taskEditModal用）
    private var editingTaskID: UUID? {
        if case .task(let id) = editingField {
            return id
        }
        return nil
    }

    private var fullSessionEditModal: some View {
        EditableModal(
            title: "Edit Session",
            onSave: {
                if !isSaveDisabled {
                    closeInputBar()
                    commitDrafts()
                    onSave()
                }
            },
            onCancel: {
                closeInputBar()
                resetDrafts()
                onCancel()
            },
            isSaveDisabled: isSaveDisabled,
            isKeyboardCloseVisible: editingField != .none,
            onKeyboardClose: closeInputBar,
            focusedRowID: $focusedRowID,
            ensureVisibleMode: .none,
            bottomBar: { inputBarView() },
            content: {
                FullSessionEditContent(
                    sessionName: tempSessionName,
                    taskDrafts: taskDrafts,
                    duplicateIDs: duplicateTaskIDs,
                    editingField: fullSessionEditingFieldBinding,
                    onSessionNameTap: {
                        editingField = .sessionName
                        activateInputBar()
                    },
                    onTaskTap: { id in
                        editingField = .task(id: id)
                        activateInputBar()
                    },
                    onNewTaskTap: {
                        newTaskText = ""
                        editingField = .newTask
                        activateInputBar()
                    },
                    onTaskDelete: { id in
                        removeTask(with: id)
                    },
                    isAddingNewTask: editingField == .newTask
                )
            }
        )
        .presentationDetents([.large])
        .sheet(isPresented: $showLargeEditor) {
            LargeTextEditorSheet(
                text: currentEditingTextBinding,
                title: currentEditorTitle,
                placeholder: currentPlaceholder,
                onClose: { showLargeEditor = false }
            )
        }
        .onAppear {
            resetDrafts()
            hasDuplicateConflict = containsDuplicateTasks(tempTasks)
            // タップするまで入力バーは表示しない
        }
        .onChange(of: editingField) { _, newValue in
            if newValue != .none {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isInputBarFocused = true
                }
            }
        }
    }

    /// FullSessionEditContentのEditingFieldへの変換バインディング
    private var fullSessionEditingFieldBinding: Binding<FullSessionEditContent.EditingField> {
        Binding(
            get: {
                switch editingField {
                case .none: return .none
                case .sessionName: return .sessionName
                case .task(let id): return .task(id: id)
                case .newTask: return .newTask
                }
            },
            set: { newValue in
                switch newValue {
                case .none: editingField = .none
                case .sessionName: editingField = .sessionName
                case .task(let id): editingField = .task(id: id)
                case .newTask: editingField = .newTask
                }
            }
        )
    }

}

// MARK: - Helper Methods

private extension SessionEditSheetBuilder {
    func handleKeyboardClose() {
        isAnyFieldFocused = false
        focusedRowID = nil
        Task { @MainActor in
            Keyboard.dismiss()
        }
    }

    func containsDuplicateTasks(_ tasks: [String]) -> Bool {
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

    func resetDrafts() {
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

    func propagateDrafts() {
        tempTasks = taskDrafts.map(\.text)
    }

    func commitDrafts() {
        propagateDrafts()
    }

    func editingDraftID() -> UUID? {
        guard let index = context.taskIndex,
              index < taskDrafts.count else {
            return nil
        }
        return taskDrafts[index].id
    }

    /// 重複タスクIDのセット
    var duplicateTaskIDs: Set<UUID> {
        var seen: [String: UUID] = [:]
        var duplicates = Set<UUID>()
        for draft in taskDrafts {
            let key = draft.text.tsu_taskNormalizedKey
            if key.isEmpty { continue }
            if let first = seen[key] {
                duplicates.insert(first)
                duplicates.insert(draft.id)
            } else {
                seen[key] = draft.id
            }
        }
        return duplicates
    }

    /// 入力バーをアクティブにする
    func activateInputBar() {
        isAnyFieldFocused = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInputBarFocused = true
        }
    }

    /// タスクを削除する
    func removeTask(with id: UUID) {
        guard taskDrafts.count > 1,
              let index = taskDrafts.firstIndex(where: { $0.id == id }) else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        taskDrafts.remove(at: index)
        propagateDrafts()
        hasDuplicateConflict = containsDuplicateTasks(taskDrafts.map(\.text))

        // 編集中のタスクが削除された場合、別のフィールドに移動
        if case .task(let editingID) = editingField, editingID == id {
            if let nextDraft = taskDrafts[safe: min(index, taskDrafts.count - 1)] {
                editingField = .task(id: nextDraft.id)
            } else {
                editingField = .sessionName
            }
        }
    }
}
