import SwiftUI

struct SessionRowEditingView: View {
    let session: SessionName
    @Binding var editingName: String
    @Binding var editingTasks: [String]
    @Binding var editingId: UUID?
    @Binding var isCustomInputMode: Bool
    @FocusState.Binding var isNameFocused: Bool
    @FocusState.Binding var isSubtitleFocused: Bool
    let saveEdit: (UUID) async -> Void
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sessionNameSection
            descriptionsSection
            actionsSection
        }
    }

    // Session Name セクション
    private var sessionNameSection: some View {
        GroupBox("Session Name") {
            if isCustomInputMode {
                SessionNameCustomInputView(
                    editingName: $editingName,
                    editingTasks: $editingTasks,
                    isCustomInputMode: $isCustomInputMode,
                    isNameFocused: $isNameFocused
                )
            } else {
                SessionNameSelectionView(
                    editingName: $editingName,
                    editingTasks: $editingTasks,
                    isCustomInputMode: $isCustomInputMode
                )
            }
        }
    }

    // Descriptions セクション
    private var descriptionsSection: some View {
        GroupBox("Descriptions") {
            SessionDescriptionsView(
                editingName: $editingName,
                editingTasks: $editingTasks,
                isSubtitleFocused: $isSubtitleFocused
            )
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
                editingTasks = [""]
                isCustomInputMode = false
            })
            .font(DesignTokens.Fonts.caption)
            .foregroundColor(DesignTokens.MoonColors.textPrimary)
            .accessibilityIdentifier(AccessibilityIDs.SessionManager.cancelButton)
        }
    }
}
