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
            editingModeView
        } else {
            displayModeView
        }
    }

    // 編集モード用のビューを分離
    private var editingModeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            sessionNameSection
            descriptionsSection
            actionsSection
        }
    }

    // 表示モード用のビューを分離
    private var displayModeView: some View {
        HStack {
            sessionInfoView
            Spacer()
            actionButtonsView
        }
        .accessibilityIdentifier(AccessibilityIDs.SessionManager.sessionCell(id: session.id.uuidString))
    }

    // Session Name セクション
    private var sessionNameSection: some View {
        GroupBox("Session Name") {
            if isCustomInputMode {
                customInputModeView
            } else {
                existingSessionSelectionView
            }
        }
    }

    // Custom入力モード
    private var customInputModeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Enter session name", text: $editingName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isNameFocused)
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.nameField)
                    .onChange(of: isNameFocused) {  // ✅ iOS 17.0対応: 新しいonChange形式
                        // Focus handling
                    }

                Button("Select Existing") {
                    isCustomInputMode = false
                    editingName = sessionManager.defaultEntries.first?.sessionName ?? "Work"
                    editingDescriptions = sessionManager.getDescriptions(for: editingName)
                }
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
                .buttonStyle(.bordered)
            }
        }
    }

    // 既存セッション選択モード
    private var existingSessionSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Menu {
                menuContent
            } label: {
                menuLabelView
            }
            .onAppear {
                // 編集開始時に既存のセッション名が設定されている場合、そのセッションを選択状態にする
                if !editingName.isEmpty && !isCustomInputMode {
                    // 既存のセッション名が設定されている場合は何もしない（既に正しい状態）
                }
            }
        }
    }

    // メニューコンテンツ
    private var menuContent: some View {
        Group {
            // デフォルトセッション
            ForEach(sessionManager.defaultEntries) { entry in
                Button {
                    editingName = entry.sessionName
                    editingDescriptions = entry.descriptions
                } label: {
                    Text(entry.sessionName)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
            }
            Divider()
            // カスタムセッション
            ForEach(sessionManager.customEntries) { entry in
                Button {
                    editingName = entry.sessionName
                    editingDescriptions = entry.descriptions
                } label: {
                    Text(entry.sessionName)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
            }
            Divider()
            Button("Custom Input...") {
                isCustomInputMode = true
                editingName = ""
                editingDescriptions = [""]
            }
            .foregroundColor(DesignTokens.MoonColors.textPrimary)
        }
    }

    // メニューラベル
    private var menuLabelView: some View {
        HStack {
            Text(editingName.isEmpty ? "Select Session" : editingName)
                .foregroundColor(editingName.isEmpty ? DesignTokens.MoonColors.textSecondary : .moonTextPrimary)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }

    // Descriptions セクション
    private var descriptionsSection: some View {
        GroupBox("Descriptions") {
            VStack(alignment: .leading, spacing: 8) {
                descriptionHeaderView
                descriptionListView
                addDescriptionButtonView
            }
        }
    }

    // Description ヘッダー
    private var descriptionHeaderView: some View {
        HStack {
            Text("Descriptions")
                .font(.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            if !editingName.isEmpty {
                Text("for \"\(editingName)\"")
                    .font(.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
        }
    }

    // Description リスト
    private var descriptionListView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(editingDescriptions.indices, id: \.self) { idx in
                descriptionRowView(at: idx)
            }
        }
    }

    // Description 行
    private func descriptionRowView(at idx: Int) -> some View {
        HStack {
            // インデント表現
            Rectangle()
                .fill(Color.clear)
                .frame(width: 16, height: 1)

            TextField("Description \(idx + 1)", text: Binding(
                get: { editingDescriptions[safe: idx] ?? "" },
                set: { newValue in
                    if idx < editingDescriptions.count {
                        editingDescriptions[idx] = newValue
                    }
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .accessibilityIdentifier(AccessibilityIDs.SessionManager.descriptionField)
            .focused($isSubtitleFocused)
            .onChange(of: isSubtitleFocused) {  // ✅ iOS 17.0対応: 新しいonChange形式
                // Focus handling
            }

            Button(action: { editingDescriptions.remove(at: idx) }, label: {
                Image(systemName: "minus.circle")
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
            })
            .buttonStyle(.plain)
            .disabled(editingDescriptions.count == 1)
        }
    }

    // Add Description ボタン
    private var addDescriptionButtonView: some View {
        HStack {
            // インデント表現
            Rectangle()
                .fill(Color.clear)
                .frame(width: 16, height: 1)

            Button(action: { editingDescriptions.append("") }, label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                    Text("Add Subtitle")
                }
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
            })
            .font(DesignTokens.Fonts.caption)
            .buttonStyle(.plain)
            .disabled(
                editingName.isEmpty ||
                (
                    editingDescriptions.first?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty ?? true
                )
            )

            Spacer()
        }
    }

    // Actions セクション
    private var actionsSection: some View {
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
                editingDescriptions = [""]
                isCustomInputMode = false
            })
            .font(DesignTokens.Fonts.caption)
            .foregroundColor(DesignTokens.MoonColors.textPrimary)
            .accessibilityIdentifier(AccessibilityIDs.SessionManager.cancelButton)
        }
    }

    // Session情報表示
    private var sessionInfoView: some View {
        VStack(alignment: .leading) {
            Text(session.name)
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)

            ForEach(session.subtitles) { subtitle in
                Text(subtitle.text)
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
        }
    }

    // アクションボタン
    private var actionButtonsView: some View {
        HStack {
            Button("Edit", action: {
                editingId = session.id
                editingName = session.name
                editingDescriptions = session.subtitles.map { $0.text }
                isCustomInputMode = false  // 編集開始時は既存セッション選択モード
            })
            .font(DesignTokens.Fonts.caption)
            .foregroundColor(DesignTokens.MoonColors.textPrimary)
            .accessibilityIdentifier(AccessibilityIDs.SessionManager.editButton)

            Button(role: .destructive, action: {
                showDeleteAlert = AlertID(id: session.id)
            }, label: {
                Image(systemName: "trash")
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
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
