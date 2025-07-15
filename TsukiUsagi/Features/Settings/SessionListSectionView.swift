import SwiftUI

struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}

struct SessionListSectionView: View {
    @EnvironmentObject var sessionManager: SessionManagerV2
    @State private var editingId: UUID?
    @State private var editingName: String = ""
    @State private var editingSubtitles: [String] = []
    @State private var errorMessage: IdentifiableError?
    @FocusState private var isNameFocused: Bool
    @FocusState private var isSubtitleFocused: Bool

    var body: some View {
        List {
            Section(header: Text("Default Sessions")) {
                if sessionManager.defaultEntries.isEmpty {
                    Text("No default sessions.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(sessionManager.defaultEntries) { entry in
                        sessionRow(entry: entry)
                    }
                }
            }
            Section(header: Text("Custom Sessions")) {
                if sessionManager.customEntries.isEmpty {
                    Text("No custom sessions. Tap + to add.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(sessionManager.customEntries) { entry in
                        sessionRow(entry: entry)
                    }
                }
            }
        }
        .alert(item: $errorMessage) { _err in
            Alert(
                title: Text("Error"),
                message: Text(_err.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: isNameFocused) { _, newValue in
            if newValue {
                HapticManager.shared.heavyImpact()
            }
        }
        .onChange(of: isSubtitleFocused) { _, newValue in
            if newValue {
                HapticManager.shared.heavyImpact()
            }
        }
    }

    @ViewBuilder
    private func sessionRow(entry: SessionEntry) -> some View {
        if editingId == entry.id {
            VStack(alignment: .leading) {
                TextField("Session Name", text: $editingName)
                    .focused($isNameFocused)
                ForEach(editingSubtitles.indices, id: \.self) { _idx in
                    TextField("Subtitle", text: Binding(
                        get: { editingSubtitles[_idx] },
                        set: { editingSubtitles[_idx] = $0 }
                    ))
                    .focused($isSubtitleFocused)
                }
                HStack {
                    Button("Save") {
                        sessionManager.editEntry(
                            id: entry.id,
                            sessionName: editingName.isEmpty ? nil : editingName,
                            subtitles: editingSubtitles
                        )
                        editingId = nil
                    }
                    Button("Cancel") {
                        editingId = nil
                    }
                }
            }
        } else {
            VStack(alignment: .leading) {
                Text(entry.sessionName ?? "(No Name)")
                ForEach(entry.subtitles, id: \.self) { subtitle in
                    Text(subtitle).font(.subheadline).foregroundColor(.secondary)
                }
                HStack {
                    Button("Edit") {
                        editingId = entry.id
                        editingName = entry.sessionName ?? ""
                        editingSubtitles = entry.subtitles
                    }
                    Button(role: .destructive) {
                        sessionManager.deleteEntry(id: entry.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
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
