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
    @State private var editingSessionContext: SessionEditContext? = nil
    @State private var tempSessionName: String = ""
    @State private var tempSubtitles: [String] = []
    @State private var tempSubtitleText: String = ""
    @State private var isViewFullyLoaded: Bool = false
    @State private var hasScrolledOnce: Bool = false
    @State private var isAnyFieldFocused: Bool = false

    var body: some View {
        RoundedCard(backgroundColor: DesignTokens.Colors.moonCardBG) {
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
            case .subtitleOnly:
                // Default Session: Subtitle管理（追加/編集/削除）
                EditableModal(
                    title: "Manage Descriptions",
                    onSave: {
                        saveSubtitleEdit(context: context)
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
                    }
                ) {
                    SubtitleEditContent(
                        sessionName: context.sessionName,
                        subtitles: context.subtitles,
                        editingIndex: context.subtitleIndex,
                        onSubtitlesChange: { _ in },
                        isAnyFieldFocused: $isAnyFieldFocused,
                        onClearFocus: {
                            isAnyFieldFocused = false
                        }
                    )
                }
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
                    }
                ) {
                    FullSessionEditContent(
                        sessionName: context.sessionName,
                        subtitles: context.subtitles,
                        onSessionNameChange: { _ in },
                        onSubtitlesChange: { _ in },
                        isAnyFieldFocused: $isAnyFieldFocused,
                        onClearFocus: {
                            isAnyFieldFocused = false
                        }
                    )
                }
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
                            subtitles: entry.subtitles
                        )
                        tempSessionName = entry.sessionName
                        tempSubtitles = entry.subtitles
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        sessionManager.deleteEntry(id: entry.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Subtitles with different behavior for Default vs Custom Sessions
            if !entry.subtitles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(entry.subtitles.enumerated()), id: \.offset) { index, subtitle in
                        if isDefault {
                            // Default Session: subtitle編集可能（モーダルで）
                            subtitleEditableRow(subtitle: subtitle, entry: entry, index: index)
                        } else {
                            // Custom Session: subtitle表示のみ（session全体編集はEditボタンで）
                            subtitleDisplayRow(subtitle: subtitle)
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

    // MARK: - Subtitle Row Builders

    @ViewBuilder
    private func subtitleEditableRow(subtitle: String, entry: SessionEntry, index: Int) -> some View {
        HStack {
            Text(subtitle)
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
        .accessibilityLabel("Edit subtitle: \(subtitle)")
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            editingSessionContext = SessionEditContext.subtitleEdit(
                entryId: entry.id,
                sessionName: entry.sessionName,
                subtitles: entry.subtitles,
                subtitleIndex: index  // 特定のsubtitle編集
            )
            tempSubtitles = entry.subtitles
        }
    }

    @ViewBuilder
    private func subtitleDisplayRow(subtitle: String) -> some View {
        Text(subtitle)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.leading, 16)
    }

    // MARK: - Save Methods

    private func saveSubtitleEdit(context: SessionEditContext) {
        do {
            // 新しいSessionManagerメソッドを使用
            try sessionManager.updateSessionSubtitles(
                sessionName: context.sessionName,
                newSubtitles: tempSubtitles
            )
        } catch {
            errorMessage = IdentifiableError(message: error.localizedDescription)
        }
    }

    private func saveFullSessionEdit(context: SessionEditContext) {
        guard case .fullSession = context.editMode else { return }

        do {
            // Custom Sessionの更新
            try sessionManager.addOrUpdateEntry(
                originalKey: context.sessionName.lowercased(),
                sessionName: tempSessionName,
                subtitles: tempSubtitles
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
