import SwiftUI

struct AlertID: Identifiable, Equatable {
    let id: UUID
}

struct SessionRowView: View {
    let session: SessionName
    @Binding var editingId: UUID?
    @Binding var editingName: String
    @Binding var editingSubtitles: [String]
    @Binding var showDeleteAlert: AlertID?
    let saveEdit: (UUID) async -> Void
    let deleteSession: (UUID) -> Void
    @FocusState private var isNameFocused: Bool
    @FocusState private var isSubtitleFocused: Bool

    var body: some View {
        if editingId == session.id {
            // 編集モード
            HStack {
                VStack(alignment: .leading) {
                    TextField("Session Name", text: $editingName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 160)
                        .accessibilityIdentifier(AccessibilityIDs.SessionManager.nameField)
                        .focused($isNameFocused)
                        .onChange(of: isNameFocused) { oldValue, newValue in
                            if newValue {
                                HapticManager.shared.heavyImpact()
                            }
                        }

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
                            .focused($isSubtitleFocused)
                            .onChange(of: isSubtitleFocused) { oldValue, newValue in
                                if newValue {
                                    HapticManager.shared.heavyImpact()
                                }
                            }

                            Button(action: { editingSubtitles.remove(at: idx) }, label: {
                                Image(systemName: "minus.circle")
                            })
                            .buttonStyle(.plain)
                            .disabled(editingSubtitles.count == 1)
                        }
                    }

                    Button(action: { editingSubtitles.append("") }, label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text("Add Subtitle")
                        }
                    })
                    .font(DesignTokens.Fonts.caption)
                    .buttonStyle(.plain)
                }

                Spacer()

                Button("Save", action: {
                    Task { await saveEdit(session.id) }
                })
                .font(DesignTokens.Fonts.caption)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(AccessibilityIDs.SessionManager.saveButton)

                Button("Cancel", action: {
                    editingId = nil
                    editingName = ""
                    editingSubtitles = [""]
                })
                .font(DesignTokens.Fonts.caption)
                .accessibilityIdentifier(AccessibilityIDs.SessionManager.cancelButton)
            }
        } else {
            // 表示モード
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

                Button("Edit", action: {
                    editingId = session.id
                    editingName = session.name
                    editingSubtitles = session.subtitles.map { $0.text }
                })
                .font(DesignTokens.Fonts.caption)
                .accessibilityIdentifier(AccessibilityIDs.SessionManager.editButton)

                Button(role: .destructive, action: {
                    showDeleteAlert = AlertID(id: session.id)
                }, label: {
                    Image(systemName: "trash")
                        .foregroundColor(DesignTokens.Colors.moonTextMuted)
                })
                .accessibilityIdentifier(AccessibilityIDs.SessionManager.deleteButton)
                .alert(item: $showDeleteAlert, content: { alertID in
                    Alert(
                        title: Text("Delete Session?"),
                        message: Text("Are you sure you want to delete this session name?"),
                        primaryButton: .destructive(Text("Delete"), action: {
                            deleteSession(alertID.id)
                        }),
                        secondaryButton: .cancel()
                    )
                })
            }
            .accessibilityIdentifier(AccessibilityIDs.SessionManager.sessionCell(id: session.id.uuidString))
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
            editingSubtitles: .constant([""]),
            showDeleteAlert: .constant(nil),
            saveEdit: { _ in },
            deleteSession: { _ in }
        )
        .environmentObject(SessionManagerV2())
    }
}
#endif
