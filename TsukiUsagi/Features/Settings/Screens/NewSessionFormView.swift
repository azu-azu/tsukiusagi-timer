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
    @State private var showAddTaskField = false
    @State private var errorMessage: String = ""
    @State private var showError = false
    @State private var duplicateIndices: Set<Int> = []

    @FocusState private var focusedField: FocusedField?

    private enum FocusedField: Hashable {
        case sessionName
        case newTask
        case task(Int)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                    header()
                    sessionNameSection()
                    tasksSection()
                    Spacer(minLength: 50)
                }
                .padding(DesignTokens.Padding.large)
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
            .adaptiveKeyboardCloseButton(
                isVisible: focusedField != nil,
                position: .topTrailing,
                action: {
                    KeyboardHelper.hideKeyboard { focusedField = nil }
                }
            )
        }
        .alert(Labels.State.readOnly, isPresented: $showError) {
            Button(Copy.Button.ok) { }
        } message: {
            Text(errorMessage)
        }
        .background(DesignTokens.CosmosColors.background)
        .ignoresSafeArea()
    }

}

private extension NewSessionFormView {
    // MARK: - Header

    @ViewBuilder
    func header() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            Image(systemName: "folder.badge.plus")
                .foregroundColor(DesignTokens.MoonColors.accentBlue)
                .font(DesignTokens.Fonts.symbolLarge)

            Text(Labels.Sections.createCustomSession)
                .font(DesignTokens.Fonts.title)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)

            Text(Labels.Settings.manageSessionNames) // keep messaging minimal per instruction
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
        }
    }

    // MARK: - Session Name

    @ViewBuilder
    func sessionNameSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text(Labels.InfoRow.sessionNameRequired)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            TextField(LocalizedStringKey("session_name_placeholder"), text: $sessionName)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
                .background(DesignTokens.CosmosColors.cardBackground)
                .cornerRadius(DesignTokens.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(DesignTokens.BlackColors.stroke, lineWidth: 1)
                )
                .focused($focusedField, equals: .sessionName)

            Text(Labels.Settings.manageSessionNames)
                .font(.caption2)
                .foregroundColor(DesignTokens.UtilityColors.duplicateWarning)
        }
    }

    // MARK: - Tasks

    @ViewBuilder
    func tasksSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            HStack {
                Text(Labels.InfoRow.tasksOptional)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                Spacer()
                Button {
                    showAddTaskField = true
                    newTask = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(DesignTokens.MoonColors.accentBlue)
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

            if showAddTaskField {
                addTaskField()
            }

            // Match default Manage Tasks helper text
            Text(LocalizedStringKey("settings_add_tasks_description"))
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
        }
    }

    @ViewBuilder
    func taskRow(task: String, index: Int) -> some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            TextField(LocalizedStringKey("task_placeholder"), text: Binding(
                get: { tasks[safe: index] ?? "" },
                set: { newValue in
                    if index < tasks.count {
                        tasks[index] = newValue
                        if !duplicateIndices.isEmpty {
                            duplicateIndices = findDuplicateIndices(in: tasks)
                        }
                    }
                }
            ))
            .textFieldStyle(PlainTextFieldStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DesignTokens.CosmosColors.cardBackground)
            .foregroundColor(
                duplicateIndices.contains(index)
                    ? DesignTokens.UtilityColors.duplicateWarning
                    : DesignTokens.MoonColors.textPrimary
            )
            .cornerRadius(DesignTokens.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(
                        duplicateIndices.contains(index)
                            ? DesignTokens.UtilityColors.duplicateWarning
                            : DesignTokens.BlackColors.stroke,
                        lineWidth: 1
                    )
            )
            .focused($focusedField, equals: .task(index))

            Button {
                tasks.remove(at: index)
                if !duplicateIndices.isEmpty {
                    duplicateIndices = findDuplicateIndices(in: tasks)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentOrange)
                    .font(DesignTokens.Fonts.symbolMedium)
            }
        }
    }

    @ViewBuilder
    func addTaskField() -> some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            TextField(LocalizedStringKey("new_task_placeholder"), text: $newTask)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
                .background(DesignTokens.CosmosColors.cardBackground)
                .cornerRadius(DesignTokens.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(DesignTokens.BlackColors.stroke, lineWidth: 1)
                )
                .focused($focusedField, equals: .newTask)

            Button {
                let trimmed = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    tasks.append(trimmed)
                    newTask = ""
                }
                if !duplicateIndices.isEmpty {
                    duplicateIndices = findDuplicateIndices(in: tasks)
                }
                showAddTaskField = false
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentGreen)
                    .font(DesignTokens.Fonts.symbolMedium)
            }

            Button {
                showAddTaskField = false
                newTask = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentOrange)
                    .font(DesignTokens.Fonts.symbolMedium)
            }
        }
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

#if DEBUG
struct NewSessionFormView_Previews: PreviewProvider {
    static var previews: some View {
        NewSessionFormView()
            .environmentObject(SessionManager())
            .padding()
            .background(DesignTokens.CosmosColors.background)
    }
}
#endif
