import SwiftUI

@available(*, deprecated, message: "Use NewSessionFormView")

struct CreateCustomSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionManager: SessionManager

    @State private var sessionName: String = ""
    @State private var descriptions: [String] = []
    @State private var newDescription: String = ""
    @State private var showAddDescriptionField = false
    @State private var errorMessage: String = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    createSessionHeader()

                    // Session Name Section
                    sessionNameSection()

                    // Descriptions Section
                    descriptionsSection()

                    Spacer(minLength: 50)
                }
                .padding()
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
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Create Session Header

    @ViewBuilder
    private func createSessionHeader() -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

    // MARK: - Session Name Section

    @ViewBuilder
    private func sessionNameSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("session_name_required_label", comment: ""))
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            TextField(NSLocalizedString("session_name_placeholder", comment: ""), text: $sessionName)
                .textFieldStyle(.roundedBorder)

            Text(NSLocalizedString("session_name_hint", comment: ""))
                .font(.caption2)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
        }
    }

    // MARK: - Descriptions Section

    @ViewBuilder
    private func descriptionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
                }
            }

            Text(NSLocalizedString("descriptions_help_text", comment: ""))
                .font(.caption2)
                .foregroundColor(DesignTokens.MoonColors.textMuted)

            if descriptions.isEmpty {
                emptyDescriptionsView()
            } else {
                LazyVStack(spacing: 8) {
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
        VStack(spacing: 8) {
            Image(systemName: "text.bubble")
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(DesignTokens.Fonts.symbolLarge)

            Text(NSLocalizedString("no_descriptions_title", comment: ""))
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textMuted)

            Text(NSLocalizedString("tap_plus_to_add_description", comment: ""))
                .font(.caption2)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignTokens.MoonColors.textMuted.opacity(0.05))
        )
    }

    @ViewBuilder
    private func descriptionRow(description: String, index: Int) -> some View {
        HStack(spacing: 8) {
            TextField(NSLocalizedString("description_placeholder", comment: ""), text: Binding(
                get: { descriptions[safe: index] ?? "" },
                set: { newValue in
                    if index < descriptions.count {
                        descriptions[index] = newValue
                    }
                }
            ))
            .textFieldStyle(.roundedBorder)

            Button {
                descriptions.remove(at: index)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentOrange)
            }
        }
    }

    @ViewBuilder
    private func addDescriptionField() -> some View {
        HStack(spacing: 8) {
            TextField(NSLocalizedString("new_description_placeholder", comment: ""), text: $newDescription)
                .textFieldStyle(.roundedBorder)

            Button {
                if !newDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    descriptions.append(newDescription.trimmingCharacters(in: .whitespacesAndNewlines))
                    newDescription = ""
                }
                showAddDescriptionField = false
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentGreen)
            }

            Button {
                showAddDescriptionField = false
                newDescription = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentOrange)
            }
        }
    }

    // MARK: - Helper Methods

    private func createSession() {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Session name cannot be empty"
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
struct CreateCustomSessionView_Previews: PreviewProvider {
    static var previews: some View {
        CreateCustomSessionView()
            .environmentObject(SessionManager())
    }
}
#endif
