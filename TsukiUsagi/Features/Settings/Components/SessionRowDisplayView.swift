import SwiftUI

struct SessionRowDisplayView: View {
    let session: SessionName
    @Binding var editingId: UUID?
    @Binding var editingName: String
    @Binding var editingDescriptions: [String]
    @Binding var showDeleteAlert: AlertID?
    @Binding var isCustomInputMode: Bool
    let deleteSession: (UUID) -> Void

    var body: some View {
        HStack {
            sessionInfoView
            Spacer()
            actionButtonsView
        }
        .accessibilityIdentifier(AccessibilityIDs.SessionManager.sessionCell(id: session.id.uuidString))
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
