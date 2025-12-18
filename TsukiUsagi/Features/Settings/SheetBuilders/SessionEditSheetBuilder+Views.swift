import SwiftUI

// MARK: - Private Views

extension SessionEditSheetBuilder {
    var taskEditModal: some View {
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
                        editingTaskText = taskDrafts.first(where: { $0.id == id })?.text ?? ""
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
        }
        .onChange(of: editingField) { _, newValue in
            if newValue != .none {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isInputBarFocused = true
                }
            }
        }
    }

    var fullSessionEditModal: some View {
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
                        editingTaskText = taskDrafts.first(where: { $0.id == id })?.text ?? ""
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
    var fullSessionEditingFieldBinding: Binding<FullSessionEditContent.EditingField> {
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

    /// 現在編集中のタスクID
    var editingTaskID: UUID? {
        if case .task(let id) = editingField {
            return id
        }
        return nil
    }
}

// MARK: - Helper Methods

extension SessionEditSheetBuilder {
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

        if case .task(let editingID) = editingField, editingID == id {
            if let nextDraft = taskDrafts[safe: min(index, taskDrafts.count - 1)] {
                editingField = .task(id: nextDraft.id)
            } else {
                editingField = .sessionName
            }
        }
    }
}
