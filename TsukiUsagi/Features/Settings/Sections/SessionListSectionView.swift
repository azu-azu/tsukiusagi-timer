import SwiftUI

struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}

struct SessionListSectionView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var editingId: UUID?
    @State private var editingName: String = ""
    @State private var editingSubtitles: [String] = []
    @State private var errorMessage: IdentifiableError?
    @State private var originalKey: String = ""
    @FocusState private var isNameFocused: Bool
    @FocusState private var isSubtitleFocused: Bool

    var body: some View {
        RoundedCard(backgroundColor: DesignTokens.Colors.moonCardBG) {
            VStack(alignment: .leading, spacing: 16) {
                section(title: "Default Sessions", entries: sessionManager.defaultEntries, isDefault: true)
                section(title: "Custom Sessions", entries: sessionManager.customEntries, isDefault: false)
            }
            .padding(.bottom, 8)
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
    private func section(title: String, entries: [SessionEntry], isDefault: Bool) -> some View {
        // ここのspacingはタイトルとタイトル下の余白
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DesignTokens.Fonts.sectionTitle)
                .padding(.horizontal)

            if entries.isEmpty {
                Text(isDefault ? "No default sessions." : "No custom sessions. Tap + to add.")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            } else {
                // ここのspacingはrow間
                VStack(spacing: 4) {
                    ForEach(entries) { entry in
                        sessionRow(entry: entry, isDefault: isDefault)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func sessionRow(entry: SessionEntry, isDefault: Bool) -> some View {
        if editingId == entry.id {
            editingSessionRow(entry: entry, isDefault: isDefault)
        } else {
            displaySessionRow(entry: entry, isDefault: isDefault)
        }
    }

    @ViewBuilder
    private func editingSessionRow(entry: SessionEntry, isDefault: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Session Name", text: $editingName)
                .focused($isNameFocused)
                .textFieldStyle(.roundedBorder)

            ForEach(editingSubtitles.indices, id: \.self) { _idx in
                TextField("Subtitle", text: Binding(
                    get: { editingSubtitles[_idx] },
                    set: { editingSubtitles[_idx] = $0 }
                ))
                .foregroundColor(DesignTokens.Colors.moonTextPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)
                .focused($isSubtitleFocused)
            }

            HStack {
                Button("Save") {
                    do {
                        try sessionManager.addOrUpdateEntry(
                            originalKey: originalKey,
                            sessionName: editingName,
                            subtitles: editingSubtitles
                        )
                        editingId = nil
                    } catch {
                        errorMessage = IdentifiableError(message: error.localizedDescription)
                    }
                }
                Button("Cancel") {
                    editingId = nil
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func displaySessionRow(entry: SessionEntry, isDefault: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(entry.sessionName)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                if !isDefault {
                    Button("Edit") {
                        editingId = entry.id
                        editingName = entry.sessionName
                        editingSubtitles = entry.subtitles
                        originalKey = entry.sessionName.lowercased()
                    }
                    Button(role: .destructive) {
                        sessionManager.deleteEntry(id: entry.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            ForEach(entry.subtitles, id: \.self) { subtitle in
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}

#if DEBUG
struct SessionListSectionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionListSectionView()
            .environmentObject(SessionManager())
            .padding()
            .background(Color.black)
    }
}
#endif
