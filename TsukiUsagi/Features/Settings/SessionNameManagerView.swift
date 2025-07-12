import SwiftUI

struct AlertID: Identifiable, Equatable {
    let id: UUID
}

struct SessionNameManagerView: View {
    @EnvironmentObject var sessionManager: SessionManagerV2
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
    @State private var subtitleTexts: [String] = [""]
    @State private var errorTitle: String = "Error"
    @State private var editingSubtitles: [String] = [""]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            newSessionForm
            sessionListSection
        }
        .padding()
        .navigationTitle("Manage Session Names")
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text(errorTitle), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
        .adaptiveStarBackground()
        .task {
            do {
                try await sessionManager.loadAsync()
            } catch {
                errorTitle = "Failed to Load Sessions"
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    // 新規登録フォーム
    private var newSessionForm: some View {
        RoundedCard(backgroundColor: DesignTokens.Colors.moonCardBG) {
            VStack(alignment: .leading, spacing: 8) {
                Text("New Session Name")
                    .font(DesignTokens.Fonts.labelBold)
                    .foregroundColor(DesignTokens.Colors.moonTextPrimary)
                TextField("Session Name (required)", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isNameFocused)
                    .onSubmit { isSubtitleFocused = true }
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.nameField)
                ForEach(subtitleTexts.indices, id: \.self) { idx in
                    HStack {
                        TextField(idx == 0 ? "Subtitle (optional)" : "Subtitle \(idx + 1)", text: Binding(
                            get: { subtitleTexts[safe: idx] ?? "" },
                            set: { newValue in
                                if idx < subtitleTexts.count {
                                    subtitleTexts[idx] = newValue
                                }
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isSubtitleFocused)
                        .accessibilityIdentifier(AccessibilityIDs.SessionManager.subtitleField)
                        Button(action: { subtitleTexts.remove(at: idx) }) {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                        .disabled(subtitleTexts.count == 1)
                    }
                }
                Button(action: { subtitleTexts.append("") }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("Add Subtitle")
                    }
                }
                .font(DesignTokens.Fonts.caption)
                .buttonStyle(.plain)
                Button("Add") {
                    addSession()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.normalized.isEmpty || subtitleTexts.allSatisfy { $0.normalized.isEmpty })
                .accessibilityIdentifier(AccessibilityIDs.SessionManager.addButton)
            }
        }
    }

    // 登録済み一覧
    private var sessionListSection: some View {
        List {
            ForEach(sessionManager.sessions) { session in
                SessionRow(
                    session: session,
                    editingId: $editingId,
                    editingName: $editingName,
                    editingSubtitles: $editingSubtitles,
                    showDeleteAlert: $showDeleteAlert,
                    saveEdit: saveEdit,
                    deleteSession: deleteSession
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private struct SessionRow: View {
        let session: SessionName
        @Binding var editingId: UUID?
        @Binding var editingName: String
        @Binding var editingSubtitles: [String]
        @Binding var showDeleteAlert: AlertID?
        let saveEdit: (UUID) async -> Void
        let deleteSession: (UUID) -> Void

        var body: some View {
            if editingId == session.id {
                // 編集モード
                HStack {
                    VStack(alignment: .leading) {
                        TextField("Session Name", text: $editingName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 160)
                            .accessibilityIdentifier(AccessibilityIDs.SessionManager.nameField)
                        ForEach(editingSubtitles.indices, id: \.self) { idx in
                            HStack {
                                TextField("Subtitle \(idx + 1)", text: Binding(
                                    get: { editingSubtitles[safe: idx] ?? "" },
                                    set: { newValue in
                                        if idx < editingSubtitles.count {
                                            editingSubtitles[idx] = newValue
                                        }
                                    }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                                .accessibilityIdentifier(AccessibilityIDs.SessionManager.subtitleField)
                                Button(action: { editingSubtitles.remove(at: idx) }) {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.plain)
                                .disabled(editingSubtitles.count == 1)
                            }
                        }
                        Button(action: { editingSubtitles.append("") }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                Text("Add Subtitle")
                            }
                        }
                        .font(DesignTokens.Fonts.caption)
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Button("Save") {
                        Task { await saveEdit(session.id) }
                    }
                    .font(DesignTokens.Fonts.caption)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.saveButton)
                    Button("Cancel") {
                        editingId = nil
                        editingName = ""
                        editingSubtitles = [""]
                    }
                    .font(DesignTokens.Fonts.caption)
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.cancelButton)
                }
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text(session.name)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.moonTextPrimary)
                        ForEach(session.subtitles) { subtitle in
                            Text(subtitle.text)
                                .font(DesignTokens.Fonts.caption)
                                .foregroundColor(DesignTokens.Colors.moonTextSecondary)
                        }
                    }
                    Spacer()
                    Button("Edit") {
                        editingId = session.id
                        editingName = session.name
                        editingSubtitles = session.subtitles.map { $0.text }
                    }
                    .font(DesignTokens.Fonts.caption)
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.editButton)
                    Button(role: .destructive) {
                        showDeleteAlert = AlertID(id: session.id)
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
                .accessibilityIdentifier(AccessibilityIDs.SessionManager.sessionCell(id: session.id.uuidString))
            }
        }
    }

    private func addSession() {
        let trimmedName = name.trimmed
        let subtitles = subtitleTexts.map { $0.normalized }.filter { !$0.isEmpty }
        guard !trimmedName.isEmpty else { return }
        Task {
            do {
                let newSession = SessionName(
                    name: trimmedName,
                    subtitles: subtitles.map { Subtitle(text: $0) }
                )
                try sessionManager.addSession(newSession)
                name = ""
                subtitleTexts = subtitleTexts.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if subtitleTexts.isEmpty { subtitleTexts = [""] }
                isNameFocused = true
                try await sessionManager.saveAsync()
            } catch {
                errorTitle = "Failed to Add Session"
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func saveEdit(id: UUID) async {
        let trimmedName = editingName.trimmed
        let subtitles = editingSubtitles.map { $0.normalized }.filter { !$0.isEmpty }
        guard !trimmedName.isEmpty else {
            errorTitle = "Failed to Save Changes"
            errorMessage = "Session Name is required."
            showErrorAlert = true
            return
        }
        do {
            try sessionManager.editSession(id: id, newName: trimmedName, newSubtitles: subtitles)
            try await sessionManager.saveAsync()
            editingId = nil
            editingName = ""
            editingSubtitles = [""]
        } catch {
            errorTitle = "Failed to Save Changes"
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func deleteSession(id: UUID) {
        sessionManager.deleteSession(id: id)
        Task {
            do {
                try await sessionManager.saveAsync()
            } catch {
                errorTitle = "Failed to Delete Session"
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#if DEBUG
    struct SessionNameManagerView_Previews: PreviewProvider {
        static var previews: some View {
            SessionNameManagerView()
                .environmentObject(SessionManagerV2())
        }
    }
#endif
