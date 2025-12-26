import SwiftUI

struct SessionEditView: View {
    let session: SessionEntry
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionManager: SessionManager

    @State private var editedName: String = ""
    @State private var editedTasks: [String] = []
    @State private var showDeleteAlert = false
    @State private var showAddTaskField = false
    @State private var newTask = ""

    @FocusState private var focusedField: FocusedField?

    private enum FocusedField: Hashable {
        case editedName
        case newTask
        case task(Int)
    }

    private var isDefaultSession: Bool {
        session.isDefault
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Session Info Header
                    sessionInfoHeader()

                    // Session Name Section
                    sessionNameSection()

                    // Tasks Section
                    tasksSection()

                    // Action Buttons (for custom sessions only)
                    if !isDefaultSession {
                        actionButtons()
                    }
                }
                .padding()
            }
            .navigationTitle(
                isDefaultSession
                    ? Labels.Sections.editTasks
                    : Labels.Sections.editSession
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Copy.Button.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Copy.Button.save) {
                        saveChanges()
                    }
                    .disabled(!isSaveEnabled)
                }
            }
            .overlay(alignment: .topTrailing) {
                if focusedField != nil {
                    KeyboardCloseButton(action: {
                        KeyboardHelper.hideKeyboard { focusedField = nil }
                    })
                    .padding(.trailing, DesignTokens.Padding.large)
                    .padding(.top, DesignTokens.Padding.large)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: focusedField != nil)
        }
        .onAppear {
            loadSessionData()
        }
        .alert(Labels.Sections.deleteSession, isPresented: $showDeleteAlert) {
            Button(Copy.Button.delete, role: .destructive) {
                deleteSession()
            }
            Button(Copy.Button.cancel, role: .cancel) { }
        } message: {
            Text(LocalizedStringKey("delete_session_message \(session.sessionName)"))
        }
        .background(DesignTokens.CosmosColors.background)
        .ignoresSafeArea()
    }

    // Helpers moved to extension
}

// MARK: - SessionEditView helpers

extension SessionEditView {
    // MARK: - Session Info Header
    @ViewBuilder
    fileprivate func sessionInfoHeader() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(
                isDefaultSession
                    ? Labels.InfoRow.defaultSession
                    : Labels.InfoRow.customSession
            )
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            HStack(spacing: 8) {
                Image(systemName: session.iconName)
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
                    .font(DesignTokens.Fonts.symbolLarge)

                Text(session.sessionName)
                    .font(DesignTokens.Fonts.title)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                if isDefaultSession {
                    Text(Labels.State.readOnly)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .stroke(DesignTokens.MoonColors.textMuted.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - Session Name Section
    @ViewBuilder
    fileprivate func sessionNameSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Labels.InfoRow.sessionName)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            if isDefaultSession {
                Text(session.sessionName)
                    .font(DesignTokens.Fonts.label)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DesignTokens.MoonColors.textMuted.opacity(0.1))
                    )
                    .foregroundColor(DesignTokens.MoonColors.textMuted)

                Text(LocalizedStringKey("default_session_name_readonly_hint"))
                    .font(.caption2)
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
                    .italic()
            } else {
                TextField(LocalizedStringKey("enter_session_name_placeholder"), text: $editedName)
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
                    .focused($focusedField, equals: .editedName)
            }
        }
    }

    // MARK: - Tasks Section
    @ViewBuilder
    fileprivate func tasksSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
                }
            }

            if !editedTasks.isEmpty {
                LazyVStack(spacing: 8) {
                    ForEach(Array(editedTasks.enumerated()), id: \.offset) { index, task in
                        taskRow(task: task, index: index)
                    }
                }
            }

            if showAddTaskField {
                addTaskField()
            }

            // Match helper copy with default Manage Tasks
            Text(LocalizedStringKey("settings_add_tasks_description"))
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
        }
    }

    @ViewBuilder
    fileprivate func taskRow(task: String, index: Int) -> some View {
        HStack(spacing: 8) {
            TextField(LocalizedStringKey("task_placeholder"), text: Binding(
                get: { editedTasks[safe: index] ?? "" },
                set: { newValue in
                    if index < editedTasks.count {
                        editedTasks[index] = newValue
                    }
                }
            ))
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
            .focused($focusedField, equals: .task(index))

            Button {
                editedTasks.remove(at: index)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentOrange)
            }
        }
    }

    @ViewBuilder
    fileprivate func addTaskField() -> some View {
        HStack(spacing: 8) {
            TextField(LocalizedStringKey("new_task_placeholder"), text: $newTask)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DesignTokens.CosmosColors.cardBackground)
                .cornerRadius(DesignTokens.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(DesignTokens.BlackColors.stroke, lineWidth: 1)
                )
                .focused($focusedField, equals: .newTask)

            Button {
                if !newTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    editedTasks.append(newTask.trimmingCharacters(in: .whitespacesAndNewlines))
                    newTask = ""
                }
                showAddTaskField = false
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentGreen)
            }

            Button {
                showAddTaskField = false
                newTask = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentOrange)
            }
        }
    }

    // MARK: - Action Buttons
    @ViewBuilder
    fileprivate func actionButtons() -> some View {
        VStack(spacing: 12) {
            Button("Delete Session") {
                showDeleteAlert = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(DesignTokens.MoonColors.accentOrange)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helper Properties
    fileprivate var hasChanges: Bool {
        if isDefaultSession {
            return editedTasks != session.tasks
        } else {
            return editedName != session.sessionName || editedTasks != session.tasks
        }
    }

    /// Save is enabled only if there are changes AND, for custom sessions, the edited name is non-empty after trimming
    fileprivate var isSaveEnabled: Bool {
        guard hasChanges else { return false }
        if isDefaultSession { return true }
        return !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Helper Methods
    fileprivate func loadSessionData() {
        editedName = session.sessionName
        editedTasks = session.tasks
    }

    fileprivate func saveChanges() {
        do {
            if isDefaultSession {
                try sessionManager.updateSessionTasks(
                    sessionName: session.sessionName,
                    newTasks: editedTasks
                )
            } else {
                try sessionManager.addOrUpdateEntry(
                    originalKey: session.sessionName.lowercased(),
                    sessionName: editedName,
                    tasks: editedTasks
                )
            }
            dismiss()
        } catch {
            #if DEBUG
            print("Error saving session: \(error)")
            #endif
        }
    }

    fileprivate func deleteSession() {
        if !isDefaultSession {
            sessionManager.deleteEntry(id: session.id)
        }
        dismiss()
    }
}

#if DEBUG
struct SessionEditView_Previews: PreviewProvider {
    static var previews: some View {
        SessionEditView(session: SessionEntry(
            sessionName: "Work",
            tasks: ["Deep focus", "Meeting"],
            isDefault: true
        ))
        .environmentObject(SessionManager())
    }
}
#endif
