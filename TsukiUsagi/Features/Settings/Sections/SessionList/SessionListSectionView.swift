import SwiftUI

// MARK: - シンプルなキーボード無効化コンテナ

struct KeyboardDismissibleContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }

            content
        }
    }
}

// MARK: - メインビュー

struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}

/// セッション一覧管理のメインView
///
/// 責務：
/// - 全体的な状態管理
/// - イベントハンドリング
/// - エラー表示
/// - モーダル制御
/// - キーボード無効化対応
struct SessionListSectionView: View {
    @EnvironmentObject var sessionManager: SessionManager

    // MARK: - State Management
    @State private var errorMessage: IdentifiableError?
    @State private var editingSessionContext: SessionEditContext?
    @State private var tempSessionName: String = ""
    @State private var tempDescriptions: [String] = []
    @State private var isAnyFieldFocused: Bool = false

    var body: some View {
        KeyboardDismissibleContainer {
            RoundedCard(backgroundColor: DesignTokens.CosmosColors.cardBackground) {
                VStack(alignment: .leading, spacing: 16) {
                    defaultSessionsSection
                    customSessionsSection
                }
                .padding(.bottom, 8)
            }
            .debugSection(String(describing: Self.self), position: .topLeading)
        }
        .alert(item: $errorMessage, content: errorAlert)
        .sheet(item: $editingSessionContext, content: editSheet)
        .onChange(of: editingSessionContext) {
            handleModalDismiss()
        }
    }

    // MARK: - Private Views

    private var defaultSessionsSection: some View {
        SessionSectionBuilder(
            title: "Default Sessions",
            entries: sessionManager.defaultEntries,
            isDefault: true,
            onEditSession: handleEditSession,
            onDeleteSession: handleDeleteSession,
            onEditDescription: handleEditDescription
        )
    }

    private var customSessionsSection: some View {
        SessionSectionBuilder(
            title: "Custom Sessions",
            entries: sessionManager.customEntries,
            isDefault: false,
            onEditSession: handleEditSession,
            onDeleteSession: handleDeleteSession,
            onEditDescription: handleEditDescription
        )
    }

    // MARK: - Event Handlers

    private func handleEditSession(_ entry: SessionEntry) {
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

    private func handleDeleteSession(_ entry: SessionEntry) {
        sessionManager.deleteEntry(id: entry.id)
    }

    private func handleEditDescription(_ entry: SessionEntry, index: Int) {
        editingSessionContext = SessionEditContext.descriptionEdit(
            entryId: entry.id,
            sessionName: entry.sessionName,
            descriptions: entry.descriptions,
            descriptionIndex: index
        )
        tempDescriptions = entry.descriptions
    }

    private func handleModalDismiss() {
        if editingSessionContext == nil {
            isAnyFieldFocused = false
        }
    }

    // MARK: - Sheet Content

    private func editSheet(for context: SessionEditContext) -> some View {
        SessionEditSheetBuilder(
            context: context,
            tempSessionName: $tempSessionName,
            tempDescriptions: $tempDescriptions,
            isAnyFieldFocused: $isAnyFieldFocused,
            onSave: { saveEdit(context: context) },
            onCancel: { editingSessionContext = nil }
        )
    }

    // MARK: - Alert Content

    private func errorAlert(for error: IdentifiableError) -> Alert {
        Alert(
            title: Text("Error"),
            message: Text(error.message),
            dismissButton: .default(Text("OK"))
        )
    }

    // MARK: - Save Methods

    private func saveEdit(context: SessionEditContext) {
        do {
            switch context.editMode {
            case .descriptionOnly:
                try sessionManager.updateSessionDescriptions(
                    sessionName: context.sessionName,
                    newDescriptions: tempDescriptions
                )
            case .fullSession:
                try sessionManager.addOrUpdateEntry(
                    originalKey: context.sessionName.lowercased(),
                    sessionName: tempSessionName,
                    descriptions: tempDescriptions
                )
            }
            editingSessionContext = nil
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
