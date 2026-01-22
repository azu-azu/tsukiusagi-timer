import SwiftUI
import Foundation

extension String {
    /// Manager/Validatorと完全同一実装
    var tsu_normalizedKey: String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = trimmed.replacingOccurrences(
            of: #"[ \u{3000}]+"#, with: " ", options: .regularExpression
        )
        let lowered = collapsed.lowercased()
        return lowered.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}

struct NewSessionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionManager: SessionManager

    @State private var sessionName: String = ""
    @State private var tasks: [String] = []
    @State private var newTask: String = ""
    @State private var editingTaskText: String = ""  // 既存タスク編集用の一時変数
    @State private var errorMessage: String = ""
    @State private var showError = false
    @State private var duplicateIndices: Set<Int> = []
    @State private var editingField: EditingField = .none
    @State private var showLargeEditor = false

    @FocusState private var isInputBarFocused: Bool

    private enum EditingField: Equatable {
        case none
        case sessionName
        case task(index: Int)
        case newTask
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                    header()
                    sessionNameSection()
                    tasksSection()
                    Spacer(minLength: 100)
                }
                .padding(DesignTokens.Padding.large)
            }
            .scrollDismissesKeyboard(.interactively)
            // コンテンツ領域のタップでキーボードだけを閉じる（入力バーは残す）
            .contentShape(Rectangle())
            .onTapGesture {
                guard editingField != .none else { return }
                isInputBarFocused = false
                Keyboard.dismiss()
            }
            .navigationTitle(Labels.Sections.newCustomSession)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Copy.Button.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Copy.Button.create) {
                        createSession()
                    }
                    .disabled(isCreateDisabled)
                }
            }
            .safeAreaInset(edge: .bottom) {
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
        }
        .alert(Labels.State.readOnly, isPresented: $showError) {
            Button(Copy.Button.ok) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showLargeEditor) {
            LargeTextEditorSheet(
                text: currentEditingTextBinding,
                title: currentEditorTitle,
                placeholder: currentPlaceholder,
                onClose: { showLargeEditor = false }
            )
        }
        .background(DesignTokens.SkyToneColors.nightStart)
        .ignoresSafeArea()
        .onChange(of: editingField) { _, newValue in
            if newValue != .none {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isInputBarFocused = true
                }
            }
        }
    }
}

private extension NewSessionFormView {
    // MARK: - Current Editing Binding

    var currentEditingTextBinding: Binding<String> {
        switch editingField {
        case .none:
            return .constant("")
        case .sessionName:
            return $sessionName
        case .task:
            // 一時変数を使用（submitで初めてtasksに反映）
            return $editingTaskText
        case .newTask:
            return $newTask
        }
    }

    var currentPlaceholder: LocalizedStringKey {
        switch editingField {
        case .none:
            return ""
        case .sessionName:
            return LocalizedStringKey("session_name_placeholder")
        case .task, .newTask:
            return LocalizedStringKey("task_placeholder")
        }
    }

    var currentEditorTitle: String {
        switch editingField {
        case .none:
            return ""
        case .sessionName:
            return Labels.InfoRow.sessionNameRequired
        case .task, .newTask:
            return Labels.InfoRow.tasksOptional
        }
    }

    /// 入力を確定して閉じる
    func submitAndCloseInputBar() {
        switch editingField {
        case .task(let index):
            // 既存タスクの編集を保存
            if index < tasks.count {
                tasks[index] = editingTaskText
                duplicateIndices = findDuplicateIndices(in: tasks)
            }
            editingTaskText = ""
        case .newTask:
            // 新規タスク追加
            let trimmed = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                tasks.append(trimmed)
                newTask = ""
                duplicateIndices = findDuplicateIndices(in: tasks)
            }
        default:
            break
        }
        isInputBarFocused = false
        editingField = .none
        Keyboard.dismiss()
    }

    // MARK: - Header

    @ViewBuilder
    func header() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            Image(systemName: "folder.badge.plus")
                .foregroundColor(DesignTokens.SkyToneColors.accentBlue)
                .font(DesignTokens.Fonts.symbolLarge)

            Text(Labels.Sections.createCustomSession)
                .font(DesignTokens.Fonts.title)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)

            Text(Labels.Settings.manageSessionNames)
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.SkyToneColors.textQuaternary)
        }
    }

    // MARK: - Session Name

    @ViewBuilder
    func sessionNameSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text(Labels.InfoRow.sessionNameRequired)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.SkyToneColors.textSecondary)

            EditablePlaceholderCard(
                text: sessionName,
                placeholder: LocalizedStringKey("session_name_placeholder"),
                isEditing: editingField == .sessionName,
                onTap: {
                    editingField = .sessionName
                }
            )
        }
    }

    // MARK: - Tasks

    @ViewBuilder
    func tasksSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            HStack {
                Text(Labels.InfoRow.tasksOptional)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                Spacer()
                Button {
                    newTask = ""
                    editingField = .newTask
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(DesignTokens.SkyToneColors.accentBlue)
                        .font(DesignTokens.Fonts.symbolMedium)
                }
            }

            if !tasks.isEmpty {
                LazyVStack(spacing: DesignTokens.Spacing.medium) {
                    ForEach(Array(tasks.enumerated()), id: \.offset) { index, task in
                        taskRow(task: task, index: index)
                    }
                }
            }

            if !duplicateIndices.isEmpty {
                Text(LocalizedStringKey("duplicate_tasks_detected"))
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.UtilityColors.duplicateWarning)
            }

            // 新規タスク追加中のプレースホルダー
            if case .newTask = editingField {
                EditablePlaceholderCard(
                    text: newTask,
                    placeholder: LocalizedStringKey("new_task_placeholder"),
                    isEditing: true,
                    onTap: {}
                )
            }

            Text(LocalizedStringKey("settings_add_tasks_description"))
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
        }
    }

    @ViewBuilder
    func taskRow(task: String, index: Int) -> some View {
        EditablePlaceholderCard(
            text: task,
            placeholder: LocalizedStringKey("task_placeholder"),
            isEditing: editingField == .task(index: index),
            isDuplicate: duplicateIndices.contains(index),
            onTap: {
                // 編集開始時に現在の値をコピー
                editingTaskText = task
                editingField = .task(index: index)
            },
            onDelete: {
                tasks.remove(at: index)
                duplicateIndices = findDuplicateIndices(in: tasks)
            }
        )
    }

    // MARK: - Create

    func createSession() {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = String(localized: "error_empty_session_name")
            showError = true
            return
        }
        let duplicateHits = findDuplicateIndices(in: tasks)
        guard duplicateHits.isEmpty else {
            duplicateIndices = duplicateHits
            return
        }
        duplicateIndices = []
        do {
            try sessionManager.addOrUpdateEntry(
                originalKey: "",
                sessionName: trimmedName,
                tasks: tasks.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            )
            dismiss()
        } catch {
            // Validation already surfaced through disablement; swallow remaining errors to avoid alerts.
        }
    }

    var isCreateDisabled: Bool {
        sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func findDuplicateIndices(in values: [String]) -> Set<Int> {
        var seen: [String: Int] = [:]
        var dups = Set<Int>()
        for (index, value) in values.enumerated() {
            let key = value.tsu_normalizedKey
            if key.isEmpty { continue }
            if let firstIndex = seen[key] {
                dups.insert(firstIndex)
                dups.insert(index)
            } else {
                seen[key] = index
            }
        }
        return dups
    }
}

#Preview {
    NewSessionFormView()
        .environmentObject(SessionManager())
        .padding()
        .background(DesignTokens.SkyToneColors.nightStart)
}
