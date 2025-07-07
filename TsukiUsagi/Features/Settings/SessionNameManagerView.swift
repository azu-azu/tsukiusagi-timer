import SwiftUI

struct AlertID: Identifiable, Equatable {
    let id: UUID
}

struct SessionNameManagerView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var name: String = ""
    @State private var subtitle: String = ""
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    @FocusState private var isNameFocused: Bool
    @FocusState private var isSubtitleFocused: Bool
    @State private var editingId: UUID? = nil
    @State private var editingName: String = ""
    @State private var editingSubtitle: String = ""
    @State private var showDeleteAlert: AlertID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            newSessionForm
            sessionListSection
        }
        .padding()
        .navigationTitle("Manage Session Names")
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
        .adaptiveStarBackground()
    }

    // 新規登録フォーム
    private var newSessionForm: some View {
        RoundedCard(backgroundColor: DesignTokens.Colors.moonCardBG) {
            VStack(alignment: .leading, spacing: 8) {
                Text("New Session Name")
                    .headlineFont()
                    .foregroundColor(DesignTokens.Colors.moonTextPrimary)
                TextField("Session Name (required)", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isNameFocused)
                    .onSubmit { isSubtitleFocused = true }
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.nameField)
                TextField("Subtitle (optional)", text: $subtitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isSubtitleFocused)
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.subtitleField)
                Button("Add") {
                    addSession()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmed.isEmpty)
                .accessibilityIdentifier(AccessibilityIDs.SessionManager.addButton)
            }
        }
    }

    // 登録済み一覧
    private var sessionListSection: some View {
        List {
            fixedSessionsSection
            customSessionsSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private var fixedSessionsSection: some View {
        Section(header:
            Text("FIXED SESSIONS")
                .foregroundColor(DesignTokens.Colors.moonTextSecondary)
        ) {
            ForEach(sessionManager.fixedSessions) { item in
                FixedSessionRow(item: item)
            }
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignTokens.Colors.moonCardBG)
        )
    }

    private struct FixedSessionRow: View {
        let item: SessionItem
        var body: some View {
            HStack {
                Text(item.name)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.moonTextPrimary)
                if let s = item.subtitle, !s.isEmpty {
                    Text("| \(s)")
                        .foregroundColor(DesignTokens.Colors.moonTextSecondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var customSessionsSection: some View {
        Section(header:
            Text("CUSTOM SESSIONS")
                .foregroundColor(DesignTokens.Colors.moonTextSecondary)
        ) {
            ForEach(sessionManager.customSessions) { item in
                CustomSessionRow(
                    item: item,
                    editingId: $editingId,
                    editingName: $editingName,
                    editingSubtitle: $editingSubtitle,
                    showDeleteAlert: $showDeleteAlert,
                    saveEdit: saveEdit,
                    deleteSession: deleteSession
                )
            }
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignTokens.Colors.moonCardBG)
        )
    }

    private struct CustomSessionRow: View {
        let item: SessionItem
        @Binding var editingId: UUID?
        @Binding var editingName: String
        @Binding var editingSubtitle: String
        @Binding var showDeleteAlert: AlertID?
        let saveEdit: (UUID) -> Void
        let deleteSession: (UUID) -> Void

        var body: some View {
            if editingId == item.id {
                // 編集モード
                HStack {
                    VStack(alignment: .leading) {
                        TextField("Session Name", text: $editingName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 160)
                            .accessibilityIdentifier(AccessibilityIDs.SessionManager.nameField)
                        TextField("Subtitle", text: $editingSubtitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 160)
                            .accessibilityIdentifier(AccessibilityIDs.SessionManager.subtitleField)
                    }
                    Spacer()
                    Button("Save") {
                        saveEdit(item.id)
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.saveButton)
                    Button("Cancel") {
                        editingId = nil
                    }
                    .font(.caption)
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.cancelButton)
                }
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.moonTextPrimary)
                        if let s = item.subtitle, !s.isEmpty {
                            Text(s)
                                .captionFont()
                                .foregroundColor(DesignTokens.Colors.moonTextSecondary)
                        }
                    }
                    Spacer()
                    Button("Edit") {
                        editingId = item.id
                        editingName = item.name
                        editingSubtitle = item.subtitle ?? ""
                    }
                    .font(.caption)
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.editButton)
                    Button(role: .destructive) {
                        showDeleteAlert = AlertID(id: item.id)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(DesignTokens.Colors.moonTextMuted)
                    }
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.deleteButton)
                    .alert(item: $showDeleteAlert) { alertID in
                        Alert(
                            title: Text("Delete Session?"),
                            message: Text("Are you sure you want to delete this session name?"),
                            primaryButton: .destructive(Text("Delete")) {
                                deleteSession(alertID.id)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .accessibilityIdentifier(AccessibilityIDs.SessionManager.sessionCell(id: item.id.uuidString))
            }
        }
    }

    private func addSession() {
        let trimmedName = name.trimmed
        let trimmedSubtitle = subtitle.trimmed
        guard !trimmedName.isEmpty else { return }
        do {
            try sessionManager.addSession(SessionItem(id: UUID(), name: trimmedName, subtitle: trimmedSubtitle.isEmpty ? nil : trimmedSubtitle, isFixed: false))
            name = ""
            subtitle = ""
            isNameFocused = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func saveEdit(id: UUID) {
        let trimmedName = editingName.trimmed
        let trimmedSubtitle = editingSubtitle.trimmed
        guard !trimmedName.isEmpty else {
            errorMessage = "Session Name is required."
            showErrorAlert = true
            return
        }
        do {
            try sessionManager.editSession(id: id, newName: trimmedName, newSubtitle: trimmedSubtitle.isEmpty ? nil : trimmedSubtitle)
            editingId = nil
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func deleteSession(id: UUID) {
        sessionManager.deleteSession(id: id)
    }
}