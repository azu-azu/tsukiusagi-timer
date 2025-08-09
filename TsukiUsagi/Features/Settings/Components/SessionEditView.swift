import SwiftUI

struct SessionEditView: View {
    let session: SessionEntry
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionManager: SessionManager

    @State private var editedName: String = ""
    @State private var editedDescriptions: [String] = []
    @State private var showDeleteAlert = false
    @State private var showAddDescriptionField = false
    @State private var newDescription = ""

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

                    // Descriptions Section
                    descriptionsSection()

                    // Action Buttons (for custom sessions only)
                    if !isDefaultSession {
                        actionButtons()
                    }
                }
                .padding()
            }
            .navigationTitle(isDefaultSession ? NSLocalizedString("edit_descriptions_title", comment: "") : NSLocalizedString("edit_session_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("save", comment: "")) {
                        saveChanges()
                    }
                    .disabled(!hasChanges)
                }
            }
        }
        .onAppear {
            loadSessionData()
        }
        .alert(NSLocalizedString("delete_session_title", comment: ""), isPresented: $showDeleteAlert) {
            Button(NSLocalizedString("delete", comment: ""), role: .destructive) {
                deleteSession()
            }
            Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
        } message: {
            Text(String(format: NSLocalizedString("delete_session_message", comment: ""), session.sessionName))
        }
    }

    // MARK: - Session Info Header

    @ViewBuilder
    private func sessionInfoHeader() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isDefaultSession ? NSLocalizedString("default_session_label", comment: "") : NSLocalizedString("custom_session_label", comment: ""))
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            HStack(spacing: 8) {
                Image(systemName: session.iconName)
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
                    .font(.system(size: 20))

                Text(session.sessionName)
                    .font(DesignTokens.Fonts.title)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                if isDefaultSession {
                    Text("READ-ONLY")
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
    private func sessionNameSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("session_name_label", comment: ""))
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

                Text(NSLocalizedString("default_session_name_readonly_hint", comment: ""))
                    .font(.caption2)
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
                    .italic()
            } else {
                TextField(NSLocalizedString("enter_session_name_placeholder", comment: ""), text: $editedName)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: - Descriptions Section

    @ViewBuilder
    private func descriptionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("descriptions_label", comment: ""))
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)

                Spacer()

                Button {
                    showAddDescriptionField = true
                    newDescription = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(DesignTokens.MoonColors.accentBlue)
                }
            }

            if editedDescriptions.isEmpty {
                emptyDescriptionsView()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(editedDescriptions.enumerated()), id: \.offset) { index, description in
                        descriptionRow(description: description, index: index)
                    }
                }
            }

            if showAddDescriptionField {
                addDescriptionField()
            }
        }
    }

    @ViewBuilder
    private func emptyDescriptionsView() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "text.bubble")
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(.system(size: 20))

            Text(NSLocalizedString("no_descriptions_title", comment: ""))
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignTokens.MoonColors.textMuted.opacity(0.05))
        )
    }

    @ViewBuilder
    private func descriptionRow(description: String, index: Int) -> some View {
        HStack(spacing: 8) {
            TextField(NSLocalizedString("description_placeholder", comment: ""), text: Binding(
                get: { editedDescriptions[safe: index] ?? "" },
                set: { newValue in
                    if index < editedDescriptions.count {
                        editedDescriptions[index] = newValue
                    }
                }
            ))
            .textFieldStyle(.roundedBorder)

            Button {
                editedDescriptions.remove(at: index)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private func addDescriptionField() -> some View {
        HStack(spacing: 8) {
            TextField(NSLocalizedString("new_description_placeholder", comment: ""), text: $newDescription)
                .textFieldStyle(.roundedBorder)

            Button {
                if !newDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    editedDescriptions.append(newDescription.trimmingCharacters(in: .whitespacesAndNewlines))
                    newDescription = ""
                }
                showAddDescriptionField = false
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }

            Button {
                showAddDescriptionField = false
                newDescription = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtons() -> some View {
        VStack(spacing: 12) {
            Button("Delete Session") {
                showDeleteAlert = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helper Properties

    private var hasChanges: Bool {
        if isDefaultSession {
            return editedDescriptions != session.descriptions
        } else {
            return editedName != session.sessionName || editedDescriptions != session.descriptions
        }
    }

    // MARK: - Helper Methods

    private func loadSessionData() {
        editedName = session.sessionName
        editedDescriptions = session.descriptions
    }

    private func saveChanges() {
        do {
            if isDefaultSession {
                // Default sessions: only update descriptions
                try sessionManager.updateSessionDescriptions(
                    sessionName: session.sessionName,
                    newDescriptions: editedDescriptions
                )
            } else {
                // Custom sessions: update name and descriptions
                try sessionManager.addOrUpdateEntry(
                    originalKey: session.sessionName.lowercased(),
                    sessionName: editedName,
                    descriptions: editedDescriptions
                )
            }
            dismiss()
        } catch {
            // Handle error
            print("Error saving session: \(error)")
        }
    }

    private func deleteSession() {
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
            descriptions: ["Deep focus", "Meeting"],
            isDefault: true
        ))
        .environmentObject(SessionManager())
    }
}
#endif
