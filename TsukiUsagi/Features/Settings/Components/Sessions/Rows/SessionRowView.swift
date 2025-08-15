import SwiftUI

struct AlertID: Identifiable, Equatable {
    let id: UUID
}

struct SessionRowView: View {
    let session: SessionName
    @Binding var editingId: UUID?
    @Binding var editingName: String
    @Binding var editingDescriptions: [String]
    @Binding var showDeleteAlert: AlertID?
    let saveEdit: (UUID) async -> Void
    let deleteSession: (UUID) -> Void
    @FocusState private var isNameFocused: Bool
    @FocusState private var isSubtitleFocused: Bool
    @State private var isCustomInputMode: Bool = false
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        if editingId == session.id {
            SessionRowEditingView(
                session: session,
                editingName: $editingName,
                editingDescriptions: $editingDescriptions,
                editingId: $editingId,
                isCustomInputMode: $isCustomInputMode,
                isNameFocused: $isNameFocused,
                isSubtitleFocused: $isSubtitleFocused,
                saveEdit: saveEdit
            )
        } else {
            SessionRowDisplayView(
                session: session,
                editingId: $editingId,
                editingName: $editingName,
                editingDescriptions: $editingDescriptions,
                showDeleteAlert: $showDeleteAlert,
				isCustomInputMode: $isCustomInputMode, deleteSession: deleteSession
            )
        }
    }
}

#if DEBUG
struct SessionRowView_Previews: PreviewProvider {
    static var previews: some View {
        SessionRowView(
            session: SessionName(name: "Test Session", subtitles: [Subtitle(text: "Test Subtitle")]),
            editingId: .constant(nil),
            editingName: .constant(""),
            editingDescriptions: .constant([""]),
            showDeleteAlert: .constant(nil),
            saveEdit: { _ in },
            deleteSession: { _ in }
        )
        .environmentObject(SessionManager())
    }
}
#endif
