//
//  TaskEditContent.swift
//  TsukiUsagi
//
//  Task編集専用コンテンツView
//  責務：
//    - セッション名の固定表示（編集不可）
//    - 複数Taskの編集機能
//    - フォーカス状態管理
//    - Task追加・削除機能
//

import SwiftUI
import Foundation
import UIKit

/// Task編集専用のコンテンツView
///
/// セッション名の固定表示とTaskの編集フィールドを提供
/// 視覚的に「何が固定で何が編集可能か」を明確に示す
struct TaskEditContent: View {
    let sessionName: String
    @State private var drafts: [SessionEditSheetBuilder.TaskDraft]
    let editingID: UUID?
    let onTasksChange: ([SessionEditSheetBuilder.TaskDraft]) -> Void
    @Binding var isAnyFieldFocused: Bool
    let onClearFocus: () -> Void
    let onDuplicateStateChange: (Bool) -> Void
    let onFocusChange: (UUID?) -> Void

    @FocusState private var focusedField: UUID?
    @State private var duplicateIDs: Set<UUID> = []
    @State private var duplicateDebouncer = Debouncer(delay: 0.15)

    init(
        sessionName: String,
        taskDrafts: [SessionEditSheetBuilder.TaskDraft],
        editingID: UUID? = nil,
        onTasksChange: @escaping ([SessionEditSheetBuilder.TaskDraft]) -> Void,
        isAnyFieldFocused: Binding<Bool>,
        onClearFocus: @escaping () -> Void,
        onDuplicateStateChange: @escaping (Bool) -> Void,
        onFocusChange: @escaping (UUID?) -> Void
    ) {
        self.sessionName = sessionName
        self.editingID = editingID
        _drafts = State(initialValue: taskDrafts)
        self.onTasksChange = onTasksChange
        self._isAnyFieldFocused = isAnyFieldFocused
        self.onClearFocus = onClearFocus
        self.onDuplicateStateChange = onDuplicateStateChange
        self.onFocusChange = onFocusChange
    }

    var body: some View {
        VStack(spacing: 24) {
            sessionCategorySection
            tasksSection
        }
        .onAppear {
            validateDuplicates()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let editingID {
                    focusedField = editingID
                    onFocusChange(editingID)
                } else if let lastID = drafts.last?.id {
                    focusedField = lastID
                    onFocusChange(lastID)
                }
            }
        }
        .onChange(of: drafts) { _, _ in
            duplicateDebouncer.schedule {
                validateDuplicates()
            }
        }
        .onChange(of: focusedField) { _, newValue in
            isAnyFieldFocused = newValue != nil
            onFocusChange(newValue)
        }
        // Manage Tasks は余白リフトへ統一
        // .keyboardAwareBottomPadding(baseBottomPadding: DesignTokens.Padding.medium)
    }

}

private extension TaskEditContent {
    func clearFocus() {
        withAnimation {
            focusedField = nil
        }
        onClearFocus()
        onFocusChange(nil)
    }

    // MARK: - Private Views

    /// セッション名表示部分（編集不可）
    var sessionCategorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Labels.InfoRow.sessionName)
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack {
                Text(sessionName)
                    .font(DesignTokens.Fonts.title)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                Spacer()

                Image(systemName: "lock.fill")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
                    .accessibilityLabel("Fixed category")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    /// Tasks編集部分（複数対応）
    var tasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Labels.InfoRow.tasks)
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                Button(action: addTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.accentBlue)
                }
                .accessibilityLabel("Add task")
                .disabled(hasDuplicateConflict)
            }

            ForEach(drafts) { draft in
                HStack(alignment: .center, spacing: 12) {
                    let isDuplicate = duplicateIDs.contains(draft.id)

                    TextField(
                        "Task",
                        text: binding(for: draft.id)
                    )
                    .textFieldStyle(PlainTextFieldStyle())
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .foregroundColor(
                        isDuplicate
                            ? DesignTokens.UtilityColors.duplicateWarning
                            : DesignTokens.MoonColors.textPrimary
                    )
                    .background(DesignTokens.CosmosColors.cardBackground)
                    .cornerRadius(DesignTokens.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .stroke(
                                isDuplicate
                                    ? DesignTokens.UtilityColors.duplicateWarning
                                    : DesignTokens.BlackColors.stroke,
                                lineWidth: isDuplicate ? 2 : 1
                            )
                    )
                    .focused($focusedField, equals: draft.id)
                    .submitLabel(draft.id == drafts.last?.id ? .done : .next)
                    .onSubmit {
                        if let nextID = nextID(after: draft.id) {
                            focusedField = nextID
                        } else {
                            Keyboard.dismiss()
                            focusedField = nil
                        }
                    }

                    if drafts.count > 1 {
                        let index = drafts.firstIndex(where: { $0.id == draft.id }) ?? 0
                        Button(
                            action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                removeTask(with: draft.id)
                            },
                            label: {
                                Image(systemName: "minus.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(DesignTokens.MoonColors.accentOrange)
                            }
                        )
                        .buttonStyle(.plain)
                        .padding(.leading, 4)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Remove task \(index + 1)")
                    }
                }
                .padding(.vertical, 4)
                .background(
                    GeometryReader { geo in
                        let isFocused = (focusedField == draft.id)
                        Color.clear.preference(
                            key: FocusedRowBottomPrefKey.self,
                            value: isFocused ? geo.frame(in: .named("DescScroll")).maxY : 0
                        )
                    }
                )
            }

            Text(LocalizedStringKey("settings_add_tasks_description"))
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Helper Methods

    func binding(for id: UUID) -> Binding<String> {
        Binding(
            get: {
                drafts.first(where: { $0.id == id })?.text ?? ""
            },
            set: { newValue in
                guard let index = drafts.firstIndex(where: { $0.id == id }) else { return }
                drafts[index].text = newValue
                onTasksChange(drafts)
                duplicateDebouncer.schedule {
                    validateDuplicates()
                }
            }
        )
    }

    func addTask() {
        let newDraft = SessionEditSheetBuilder.TaskDraft(text: "")
        drafts.append(newDraft)
        onTasksChange(drafts)
        duplicateDebouncer.schedule {
            validateDuplicates()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = newDraft.id
        }
    }

    func removeTask(with id: UUID) {
        guard drafts.count > 1, let index = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts.remove(at: index)
        onTasksChange(drafts)
        duplicateDebouncer.schedule {
            validateDuplicates()
        }

        if focusedField == id {
            if let next = drafts[safe: min(index, drafts.count - 1)]?.id {
                focusedField = next
            } else {
                focusedField = drafts.last?.id
            }
        }
    }

    func validateDuplicates() {
        var seen: [String: UUID] = [:]
        var duplicates = Set<UUID>()

        let hadConflict = !duplicateIDs.isEmpty

        for draft in drafts {
            let key = draft.text.tsu_taskNormalizedKey
            if key.isEmpty { continue }
            if let first = seen[key] {
                duplicates.insert(first)
                duplicates.insert(draft.id)
            } else {
                seen[key] = draft.id
            }
        }
        duplicateIDs = duplicates
        onDuplicateStateChange(!duplicates.isEmpty)

        let hasConflict = !duplicates.isEmpty
        if hadConflict != hasConflict {
            let message = hasConflict
                ? LocalizedStringKey("duplicate_tasks_detected")
                : LocalizedStringKey("duplicate_tasks_resolved")
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    var hasDuplicateConflict: Bool {
        !duplicateIDs.isEmpty
    }

    func nextID(after id: UUID) -> UUID? {
        guard let index = drafts.firstIndex(where: { $0.id == id }) else { return nil }
        let nextIndex = drafts.index(after: index)
        return nextIndex < drafts.endIndex ? drafts[nextIndex].id : nil
    }
}
