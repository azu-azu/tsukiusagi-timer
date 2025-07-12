import SwiftUI

struct SessionListSectionView: View {
    @EnvironmentObject var sessionManager: SessionManagerV2
    @State private var editingId: UUID?
    @State private var editingName: String = ""
    @State private var editingSubtitles: [String] = [""]
    @State private var showDeleteAlert: AlertID?
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var errorTitle: String = "Error"

    var body: some View {
        List {
            ForEach(sessionManager.sessions) { session in
                SessionRowView(
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
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text(errorTitle), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
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

#if DEBUG
struct SessionListSectionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionListSectionView()
            .environmentObject(SessionManagerV2())
    }
}
#endif