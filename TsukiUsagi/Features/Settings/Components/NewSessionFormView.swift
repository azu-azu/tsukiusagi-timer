import SwiftUI

struct NewSessionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionManager: SessionManager

    @State private var sessionName: String = ""
    @State private var descriptions: [String] = []
    @State private var newDescription: String = ""
    @State private var showAddDescriptionField = false
    @State private var errorMessage: String = ""
    @State private var showError = false

    @FocusState private var focusedField: FocusedField?

    private enum FocusedField: Hashable {
        case sessionName
        case newDescription
        case description(Int)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                    header()
                    sessionNameSection()
                    descriptionsSection()
                    Spacer(minLength: 50)
                }
                .padding(DesignTokens.Padding.large)
            }
            .navigationTitle(NSLocalizedString("new_custom_session_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("create", comment: "")) {
                        createSession()
                    }
                    .disabled(sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .adaptiveKeyboardCloseButton(
                isVisible: focusedField != nil,
                position: .topTrailing,
                action: {
                    KeyboardHelper.hideKeyboard { focusedField = nil }
                }
            )
        }
        .alert(NSLocalizedString("error_title", comment: "Error"), isPresented: $showError) {
            Button(NSLocalizedString("ok", comment: "OK")) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func header() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            Image(systemName: "folder.badge.plus")
                .foregroundColor(DesignTokens.MoonColors.accentBlue)
                .font(DesignTokens.Fonts.symbolLarge)

            Text(NSLocalizedString("create_custom_session_title", comment: ""))
                .font(DesignTokens.Fonts.title)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)

            Text(NSLocalizedString("create_custom_session_description", comment: ""))
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
        }
    }

    // MARK: - Session Name

    @ViewBuilder
    private func sessionNameSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text(NSLocalizedString("session_name_required_label", comment: ""))
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            TextField(NSLocalizedString("session_name_placeholder", comment: ""), text: $sessionName)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .sessionName)

            Text(NSLocalizedString("session_name_hint", comment: ""))
                .font(.caption2)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
        }
    }

    // MARK: - Descriptions

    @ViewBuilder
    private func descriptionsSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            HStack {
                Text(NSLocalizedString("descriptions_optional_label", comment: ""))
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                Spacer()
                Button {
                    showAddDescriptionField = true
                    newDescription = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(DesignTokens.MoonColors.accentBlue)
                        .font(DesignTokens.Fonts.symbolMedium)
                }
            }

            Text(NSLocalizedString("descriptions_help_text", comment: ""))
                .font(.caption2)
                .foregroundColor(DesignTokens.MoonColors.textMuted)

            if descriptions.isEmpty {
                emptyDescriptionsView()
            } else {
                LazyVStack(spacing: DesignTokens.Spacing.medium) {
                    ForEach(Array(descriptions.enumerated()), id: \.offset) { index, description in
                        descriptionRow(description: description, index: index)
                    }
                }
            }

            if showAddDescriptionField {
                addDescriptionField()
            }
        }
    }

    @ViewBuilder
    private func emptyDescriptionsView() -> some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            Image(systemName: "text.bubble")
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(DesignTokens.Fonts.symbolMedium)

            Text(NSLocalizedString("no_descriptions_title", comment: ""))
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textMuted)

            Text(NSLocalizedString("tap_plus_to_add_description", comment: ""))
                .font(.caption2)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Padding.large)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .fill(DesignTokens.MoonColors.textMuted.opacity(0.05))
        )
    }

    @ViewBuilder
    private func descriptionRow(description: String, index: Int) -> some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            TextField(NSLocalizedString("description_placeholder", comment: ""), text: Binding(
                get: { descriptions[safe: index] ?? "" },
                set: { newValue in
                    if index < descriptions.count {
                        descriptions[index] = newValue
                    }
                }
            ))
            .textFieldStyle(.roundedBorder)
            .focused($focusedField, equals: .description(index))

            Button {
                descriptions.remove(at: index)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentOrange)
                    .font(DesignTokens.Fonts.symbolMedium)
            }
        }
    }

    @ViewBuilder
    private func addDescriptionField() -> some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            TextField(NSLocalizedString("new_description_placeholder", comment: ""), text: $newDescription)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .newDescription)

            Button {
                let trimmed = newDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    descriptions.append(trimmed)
                    newDescription = ""
                }
                showAddDescriptionField = false
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentGreen)
                    .font(DesignTokens.Fonts.symbolMedium)
            }

            Button {
                showAddDescriptionField = false
                newDescription = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentOrange)
                    .font(DesignTokens.Fonts.symbolMedium)
            }
        }
    }

    // MARK: - Create

    private func createSession() {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = NSLocalizedString("error_empty_session_name", comment: "Session name cannot be empty")
            showError = true
            return
        }
        do {
            try sessionManager.addOrUpdateEntry(
                originalKey: "",
                sessionName: trimmedName,
                descriptions: descriptions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#if DEBUG
struct NewSessionFormView_Previews: PreviewProvider {
    static var previews: some View {
        NewSessionFormView()
            .environmentObject(SessionManager())
            .padding()
            .background(DesignTokens.CosmosColors.background)
    }
}
#endif
