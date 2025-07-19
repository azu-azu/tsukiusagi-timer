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
    @State private var isCustomInputMode: Bool = false
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        if editingId == session.id {
            // 編集モード
            VStack(alignment: .leading, spacing: 12) {
                // Session Name セクション（親）
                GroupBox("Session Name") {
                    if isCustomInputMode {
                        // Custom入力モード
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("Enter session name", text: $editingName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($isNameFocused)
                                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.nameField)
                                    .onChange(of: isNameFocused) { _, newValue in
                                        if newValue {
                                            HapticManager.shared.heavyImpact()
                                        }
                                    }

                                Button("Select Existing") {
                                    isCustomInputMode = false
                                    editingName = sessionManager.defaultEntries.first?.sessionName ?? "Work"
                                    editingSubtitles = sessionManager.getSubtitles(for: editingName)
                                }
                                .font(DesignTokens.Fonts.caption)
                                .buttonStyle(.bordered)
                            }
                        }
                    } else {
                        // 既存セッション選択モード
                        VStack(alignment: .leading, spacing: 8) {
                            Menu {
                                // デフォルトセッション
                                ForEach(sessionManager.defaultEntries) { entry in
                                    Button {
                                        editingName = entry.sessionName
                                        editingSubtitles = entry.subtitles
                                    } label: {
                                        Text(entry.sessionName)
                                    }
                                }
                                Divider()
                                // カスタムセッション
                                ForEach(sessionManager.customEntries) { entry in
                                    Button {
                                        editingName = entry.sessionName
                                        editingSubtitles = entry.subtitles
                                    } label: {
                                        Text(entry.sessionName)
                                    }
                                }
                                Divider()
                                Button("Custom Input...") {
                                    isCustomInputMode = true
                                    editingName = ""
                                    editingSubtitles = [""]
                                }
                            } label: {
                                HStack {
                                    Text(editingName.isEmpty ? "Select Session" : editingName)
                                        .foregroundColor(editingName.isEmpty ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                            }
                            .onAppear {
                                // 編集開始時に既存のセッション名が設定されている場合、そのセッションを選択状態にする
                                if !editingName.isEmpty && !isCustomInputMode {
                                    // 既存のセッション名が設定されている場合は何もしない（既に正しい状態）
                                }
                            }
                        }
                    }
                }

                // Subtitles セクション（子）
                GroupBox("Subtitles") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Subtitles")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if !editingName.isEmpty {
                                Text("for \"\(editingName)\"")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // インデントで親子関係を表現
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(editingSubtitles.indices, id: \.self) { idx in
                                HStack {
                                    // インデント表現
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: 16, height: 1)

                                    TextField("Subtitle \(idx + 1)", text: Binding(
                                        get: { editingSubtitles[safe: idx] ?? "" },
                                        set: { newValue in
                                            if idx < editingSubtitles.count {
                                                editingSubtitles[idx] = newValue
                                            }
                                        }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.subtitleField)
                                    .focused($isSubtitleFocused)
                                    .onChange(of: isSubtitleFocused) { _, newValue in
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

                            HStack {
                                // インデント表現
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 16, height: 1)

                                Button(action: { editingSubtitles.append("") }, label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle")
                                        Text("Add Subtitle")
                                    }
                                })
                                .font(DesignTokens.Fonts.caption)
                                .buttonStyle(.plain)
                                .disabled(
                                    editingName.isEmpty ||
                                    (
                                        editingSubtitles.first?
                                            .trimmingCharacters(in: .whitespacesAndNewlines)
                                            .isEmpty ?? true
                                    )
                                )

                                Spacer()
                            }
                        }
                    }
                }

                // Actions セクション
                HStack {
                    Button(isCustomInputMode ? "Create Session" : "Update \"\(editingName)\"") {
                        Task { await saveEdit(session.id) }
                    }
                    .disabled(editingName.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.saveButton)

                    Button("Cancel", action: {
                        editingId = nil
                        editingName = ""
                        editingSubtitles = [""]
                        isCustomInputMode = false
                    })
                    .font(DesignTokens.Fonts.caption)
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.cancelButton)
                }
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
                    isCustomInputMode = false  // 編集開始時は既存セッション選択モード
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
        .environmentObject(SessionManager())
    }
}
#endif
