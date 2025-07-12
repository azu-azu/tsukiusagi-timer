import SwiftUI

struct NewSessionFormView: View {
    @EnvironmentObject var sessionManager: SessionManagerV2
    @State private var name: String = ""
    @State private var subtitleTexts: [String] = [""]
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @FocusState private var isNameFocused: Bool
    @FocusState private var isSubtitleFocused: Bool
    @State private var errorTitle: String = "Error"

    var body: some View {
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

                        Button(action: { subtitleTexts.remove(at: idx) }, label: {
                            Image(systemName: "minus.circle")
                        })
                        .buttonStyle(.plain)
                        .disabled(subtitleTexts.count == 1)
                    }
                }

                Button(action: { subtitleTexts.append("") }, label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("Add Subtitle")
                    }
                })
                .font(DesignTokens.Fonts.caption)
                .buttonStyle(.plain)

                Button("Add", action: {
                    addSession()
                })
                .buttonStyle(.borderedProminent)
                .disabled(name.normalized.isEmpty || subtitleTexts.allSatisfy { $0.normalized.isEmpty })
                .accessibilityIdentifier(AccessibilityIDs.SessionManager.addButton)
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text(errorTitle), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
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
}



#if DEBUG
struct NewSessionFormView_Previews: PreviewProvider {
    static var previews: some View {
        NewSessionFormView()
            .environmentObject(SessionManagerV2())
    }
}
#endif