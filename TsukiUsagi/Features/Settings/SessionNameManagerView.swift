import SwiftUI

struct AlertID: Identifiable, Equatable {
    let id: UUID
}

struct SessionNameManagerView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var name: String = ""
    @State private var detail: String = ""
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    @FocusState private var isNameFocused: Bool
    @FocusState private var isDetailFocused: Bool
    @State private var editingId: UUID? = nil
    @State private var editingName: String = ""
    @State private var editingDetail: String = ""
    @State private var showDeleteAlert: AlertID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 新規登録フォーム
            VStack(alignment: .leading, spacing: 8) {
                Text("New Session Name")
                    .font(.headline)
                TextField("Session Name (required)", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isNameFocused)
                    .onSubmit { isDetailFocused = true }
                TextField("Detail (optional)", text: $detail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isDetailFocused)
                Button("Add") {
                    addSession()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmed.isEmpty)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.moonCardBackground.opacity(0.15)))

            // 登録済み一覧
            List {
                Section(header: Text("Fixed Sessions")) {
                    ForEach(sessionManager.fixedSessions) { item in
                        HStack {
                            Text(item.name)
                                .fontWeight(.semibold)
                            if let d = item.detail, !d.isEmpty {
                                Text("| \(d)")
                                    .foregroundColor(.moonTextSecondary)
                            }
                        }
                    }
                }
                Section(header: Text("Custom Sessions")) {
                    ForEach(sessionManager.customSessions) { item in
                        if editingId == item.id {
                            // 編集モード
                            HStack {
                                VStack(alignment: .leading) {
                                    TextField("Session Name", text: $editingName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(maxWidth: 160)
                                    TextField("Detail", text: $editingDetail)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(maxWidth: 160)
                                }
                                Spacer()
                                Button("Save") {
                                    saveEdit(id: item.id)
                                }
                                .font(.caption)
                                .buttonStyle(.borderedProminent)
                                Button("Cancel") {
                                    editingId = nil
                                }
                                .font(.caption)
                            }
                        } else {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .fontWeight(.semibold)
                                    if let d = item.detail, !d.isEmpty {
                                        Text(d)
                                            .font(.caption)
                                            .foregroundColor(.moonTextSecondary)
                                    }
                                }
                                Spacer()
                                Button("Edit") {
                                    editingId = item.id
                                    editingName = item.name
                                    editingDetail = item.detail ?? ""
                                }
                                .font(.caption)
                                Button(role: .destructive) {
                                    showDeleteAlert = AlertID(id: item.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .alert(item: $showDeleteAlert) { alertID in
                                    Alert(
                                        title: Text("Delete Session?"),
                                        message: Text("Are you sure you want to delete this session name?"),
                                        primaryButton: .destructive(Text("Delete")) {
                                            deleteSession(id: alertID.id)
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .padding()
        .navigationTitle("Manage Session Names")
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
    }

    private func addSession() {
        let trimmedName = name.trimmed
        let trimmedDetail = detail.trimmed
        guard !trimmedName.isEmpty else { return }
        do {
            try sessionManager.addSession(SessionItem(id: UUID(), name: trimmedName, detail: trimmedDetail.isEmpty ? nil : trimmedDetail))
            name = ""
            detail = ""
            isNameFocused = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func saveEdit(id: UUID) {
        let trimmedName = editingName.trimmed
        let trimmedDetail = editingDetail.trimmed
        guard !trimmedName.isEmpty else {
            errorMessage = "Session Name is required."
            showErrorAlert = true
            return
        }
        do {
            try sessionManager.editSession(id: id, newName: trimmedName, newDetail: trimmedDetail.isEmpty ? nil : trimmedDetail)
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