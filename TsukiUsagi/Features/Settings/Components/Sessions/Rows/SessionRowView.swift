import SwiftUI

struct AlertID: Identifiable, Equatable {
    let id: UUID
}

struct SessionRowView: View {
    let session: SessionName
    @Binding var editingId: UUID?
    @Binding var editingName: String
    @Binding var editingTasks: [String]
    @Binding var showDeleteAlert: AlertID?
    let saveEdit: (UUID) async -> Void
    let deleteSession: (UUID) -> Void
    @FocusState private var isNameFocused: Bool
    @FocusState private var isTaskFocused: Bool
    @State private var isCustomInputMode: Bool = false
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        if editingId == session.id {
            SessionRowEditingView(
                session: session,
                editingName: $editingName,
                editingTasks: $editingTasks,
                editingId: $editingId,
                isCustomInputMode: $isCustomInputMode,
                isNameFocused: $isNameFocused,
                isTaskFocused: $isTaskFocused,
                saveEdit: saveEdit
            )
        } else {
            SessionRowDisplayView(
                session: session,
                editingId: $editingId,
                editingName: $editingName,
                editingTasks: $editingTasks,
                showDeleteAlert: $showDeleteAlert,
				isCustomInputMode: $isCustomInputMode, deleteSession: deleteSession
            )
        }
    }
}

#Preview {
    SessionRowView(
        session: SessionName(name: "Test Session", tasks: [TaskItem(text: "Test Subtitle")]),
        editingId: .constant(nil),
        editingName: .constant(""),
        editingTasks: .constant([""]),
        showDeleteAlert: .constant(nil),
        saveEdit: { _ in },
        deleteSession: { _ in }
    )
    .environmentObject(SessionManager())
}
