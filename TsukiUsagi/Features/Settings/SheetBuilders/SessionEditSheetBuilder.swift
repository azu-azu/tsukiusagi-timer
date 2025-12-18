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

    @State var hasDuplicateConflict = false
    @State var taskDrafts: [TaskDraft] = []
    @State var focusedRowID: UUID?
    @State var editingField: EditingField = .none
    @State var newTaskText: String = ""
    @State var editingTaskText: String = ""
    @State var showLargeEditor = false
    @FocusState var isInputBarFocused: Bool

    var initialSessionName: String { context.sessionName }
    var initialTasks: [String] { context.tasks }

    var hasChanges: Bool {
        if context.isDefaultSession {
            return taskDrafts.map(\.text) != initialTasks
        } else {
            return tempSessionName != initialSessionName || taskDrafts.map(\.text) != initialTasks
        }
    }

    var isSaveDisabled: Bool {
        if hasDuplicateConflict { return true }
        if !hasChanges { return true }
        if !context.isDefaultSession {
            let trimmed = tempSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return true }
        }
        return false
    }

    // MARK: - Input Bar Bindings

    var currentEditingTextBinding: Binding<String> {
        switch editingField {
        case .none:
            return .constant("")
        case .sessionName:
            return $tempSessionName
        case .task:
            return $editingTaskText
        case .newTask:
            return $newTaskText
        }
    }

    var currentPlaceholder: LocalizedStringKey {
        switch editingField {
        case .none:
            return ""
        case .sessionName:
            return LocalizedStringKey("enter_session_name_placeholder")
        case .task, .newTask:
            return LocalizedStringKey("task_placeholder")
        }
    }

    var currentEditorTitle: String {
        switch editingField {
        case .none:
            return ""
        case .sessionName:
            return Labels.InfoRow.sessionName
        case .task, .newTask:
            return Labels.InfoRow.tasksOptional
        }
    }

    /// 入力バーを閉じる（保存しない）
    func closeInputBar() {
        editingTaskText = ""
        newTaskText = ""
        isInputBarFocused = false
        editingField = .none
        isAnyFieldFocused = false
        Keyboard.dismiss()
    }

    /// 入力を確定して閉じる
    func submitAndCloseInputBar() {
        switch editingField {
        case .task(let id):
            if let index = taskDrafts.firstIndex(where: { $0.id == id }) {
                taskDrafts[index].text = editingTaskText
                propagateDrafts()
                hasDuplicateConflict = containsDuplicateTasks(taskDrafts.map(\.text))
            }
            editingTaskText = ""
        case .newTask:
            let trimmed = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let newDraft = TaskDraft(text: trimmed)
                taskDrafts.append(newDraft)
                propagateDrafts()
                hasDuplicateConflict = containsDuplicateTasks(taskDrafts.map(\.text))
            }
            newTaskText = ""
        default:
            break
        }
        isInputBarFocused = false
        editingField = .none
        isAnyFieldFocused = false
        Keyboard.dismiss()
    }

    @ViewBuilder
    func inputBarView() -> some View {
        if editingField != .none {
            BottomInputBar(
                text: currentEditingTextBinding,
                isFocused: $isInputBarFocused,
                placeholder: currentPlaceholder,
                onExpand: {
                    showLargeEditor = true
                },
                onSubmit: {
                    submitAndCloseInputBar()
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
}
