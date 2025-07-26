import SwiftUI

struct SessionNameCustomInputView: View {
    @Binding var editingName: String
    @Binding var editingDescriptions: [String]
    @Binding var isCustomInputMode: Bool
    @FocusState.Binding var isNameFocused: Bool
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Enter session name", text: $editingName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isNameFocused)
                    .accessibilityIdentifier(AccessibilityIDs.SessionManager.nameField)
                    .onChange(of: isNameFocused) {
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
}
