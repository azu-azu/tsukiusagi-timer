import SwiftUI

struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - Main View

struct SessionListSectionView: View {
    @EnvironmentObject var sessionManager: SessionManager

    // エラー表示用
    @State private var errorMessage: IdentifiableError?

    // Session編集用の状態管理
    @State private var editingSessionContext: SessionEditContext?
    @State private var tempSessionName: String = ""
    @State private var tempDescriptions: [String] = []
    @State private var tempDescriptionText: String = ""
    @State private var isViewFullyLoaded: Bool = false
    @State private var hasScrolledOnce: Bool = false
    @State private var isAnyFieldFocused: Bool = false

    var body: some View {
        RoundedCard(backgroundColor: DesignTokens.Colors.cosmosCardBG) {
            VStack(alignment: .leading, spacing: 16) {
                section(title: "Default Sessions", entries: sessionManager.defaultEntries, isDefault: true)
                section(title: "Custom Sessions", entries: sessionManager.customEntries, isDefault: false)
            }
            .padding(.bottom, 8)
        }
        .debugSection(String(describing: Self.self), position: .topLeading)
        .alert(item: $errorMessage) { _err in
            Alert(
                title: Text("Error"),
                message: Text(_err.message),
                dismissButton: .default(Text("OK"))
            )
        }
        // Session編集モーダル
        .sheet(item: $editingSessionContext) { context in
            switch context.editMode {
            case .descriptionOnly:
                // Default Session: Description管理（追加/編集/削除）
                EditableModal(
                    title: "Manage Descriptions",
                    onSave: {
                        saveDescriptionEdit(context: context)
                        editingSessionContext = nil
                    },
                    onCancel: {
                        editingSessionContext = nil
                    },
                    isKeyboardCloseVisible: isAnyFieldFocused,
                    onKeyboardClose: {
                        KeyboardManager.hideKeyboard {
                            isAnyFieldFocused = false
                        }
                    },
                    content: {
                        DescriptionEditContent(
                            sessionName: context.sessionName,
                            descriptions: tempDescriptions, // 修正: contextではなくtempDescriptionsを使用
                            editingIndex: context.descriptionIndex,
                            onDescriptionsChange: { newDescriptions in
                                // 修正: tempDescriptionsを更新してUIと同期
                                tempDescriptions = newDescriptions
                            },
                            isAnyFieldFocused: $isAnyFieldFocused,
                            onClearFocus: {
                                isAnyFieldFocused = false
                            }
                        )
                    }
                )
                .presentationDetents([.large])

            case .fullSession:
                // Custom Session: Session全体編集
                EditableModal(
                    title: "Edit Session",
                    onSave: {
                        saveFullSessionEdit(context: context)
                        editingSessionContext = nil
                    },
                    onCancel: {
                        editingSessionContext = nil
                    },
                    isKeyboardCloseVisible: isAnyFieldFocused,
                    onKeyboardClose: {
                        KeyboardManager.hideKeyboard {
                            isAnyFieldFocused = false
                        }
                    },
                    content: {
                        FullSessionEditContent(
                            sessionName: tempSessionName, // 修正: contextではなくtempSessionNameを使用
                            descriptions: tempDescriptions, // 修正: contextではなくtempDescriptionsを使用
                            onSessionNameChange: { newName in
                                // 修正: tempSessionNameを更新してUIと同期
                                tempSessionName = newName
                            },
                            onDescriptionsChange: { newDescriptions in
                                // 修正: tempDescriptionsを更新してUIと同期
                                tempDescriptions = newDescriptions
                            },
                            isAnyFieldFocused: $isAnyFieldFocused,
                            onClearFocus: {
                                isAnyFieldFocused = false
                            }
                        )
                    }
                )
                .presentationDetents([.large])
            }
        }
        .onChange(of: editingSessionContext) { _, newValue in
            // モーダルが閉じられた時にフォーカス状態をリセット
            if newValue == nil {
                isAnyFieldFocused = false
            }
        }
    }

    // MARK: - Section Builder

    @ViewBuilder
    private func section(title: String, entries: [SessionEntry], isDefault: Bool) -> some View {
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
                VStack(spacing: 4) {
                    ForEach(entries) { entry in
                        displaySessionRow(entry: entry, isDefault: isDefault)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func displaySessionRow(entry: SessionEntry, isDefault: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(entry.sessionName)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                if !isDefault {
                    Button("Edit") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()

                        editingSessionContext = SessionEditContext.fullSessionEdit(
                            entryId: entry.id,
                            sessionName: entry.sessionName,
                            descriptions: entry.descriptions
                        )
                        tempSessionName = entry.sessionName
                        tempDescriptions = entry.descriptions
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive, action: {
                        sessionManager.deleteEntry(id: entry.id)
                    }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Subtitles with different behavior for Default vs Custom Sessions
            if !entry.descriptions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(entry.descriptions.enumerated()), id: \.offset) { index, description in
                        if isDefault {
                            // Default Session: description編集可能（モーダルで）
                            descriptionEditableRow(description: description, entry: entry, index: index)
                        } else {
                            // Custom Session: description表示のみ（session全体編集はEditボタンで）
                            descriptionDisplayRow(description: description)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            Group {
                if !isDefault {
                    // 編集可能な項目は背景で一体感を演出
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                } else {
                    // デフォルト項目はシンプルに
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.02))
                }
            }
        )
    }

    // MARK: - Description Row Builders

    @ViewBuilder
    private func descriptionEditableRow(description: String, entry: SessionEntry, index: Int) -> some View {
        HStack {
            Text(description)
                .font(.subheadline)
                .italic()
                .foregroundColor(.white.opacity(0.6))
                .padding(.leading, 16)

            Spacer()

            Image(systemName: "pencil")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
                .padding(.trailing, 8)
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .background(Color.white.opacity(0.02))
        )
        .contentShape(Rectangle())
        .accessibilityLabel("Edit description: \(description)")
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            editingSessionContext = SessionEditContext.descriptionEdit(
                entryId: entry.id,
                sessionName: entry.sessionName,
                descriptions: entry.descriptions,
                descriptionIndex: index  // 特定のdescription編集
            )
            tempDescriptions = entry.descriptions
        }
    }

    @ViewBuilder
    private func descriptionDisplayRow(description: String) -> some View {
        Text(description)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.leading, 16)
    }

    // MARK: - Save Methods

    private func saveDescriptionEdit(context: SessionEditContext) {
        do {
            // tempDescriptionsを使用（UIで編集された最新状態）
            try sessionManager.updateSessionDescriptions(
                sessionName: context.sessionName,
                newDescriptions: tempDescriptions
            )
        } catch {
            errorMessage = IdentifiableError(message: error.localizedDescription)
        }
    }

    private func saveFullSessionEdit(context: SessionEditContext) {
        guard case .fullSession = context.editMode else { return }

        do {
            // tempSessionName と tempSubtitles を使用（UIで編集された最新状態）
            try sessionManager.addOrUpdateEntry(
                originalKey: context.sessionName.lowercased(),
                sessionName: tempSessionName,
                descriptions: tempDescriptions
            )
        } catch {
            errorMessage = IdentifiableError(message: error.localizedDescription)
        }
    }
}

// MARK: - Preview

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
