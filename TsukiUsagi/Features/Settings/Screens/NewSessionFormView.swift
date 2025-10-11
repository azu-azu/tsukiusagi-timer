import SwiftUI
import Foundation

extension String {
    /// Manager/Validatorと完全同一実装
    var tsu_normalizedKey: String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = trimmed.replacingOccurrences(
            of: #"[ \u{3000}]+"#, with: " ", options: .regularExpression
        )
        let lowered = collapsed.lowercased()
        return lowered.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}

struct NewSessionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionManager: SessionManager

    @State private var sessionName: String = ""
    @State private var descriptions: [String] = []
    @State private var newDescription: String = ""
    @State private var showAddDescriptionField = false
    @State private var errorMessage: String = ""
    @State private var showError = false
    @State private var duplicateIndices: Set<Int> = []

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
                    .disabled(isCreateDisabled)
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
        .background(DesignTokens.CosmosColors.background)
        .ignoresSafeArea()
    }

}

private extension NewSessionFormView {
    // MARK: - Header

    @ViewBuilder
    func header() -> some View {
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
    func sessionNameSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text(NSLocalizedString("session_name_required_label", comment: ""))
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            TextField(NSLocalizedString("session_name_placeholder", comment: ""), text: $sessionName)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DesignTokens.CosmosColors.cardBackground)
                .cornerRadius(DesignTokens.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(DesignTokens.BlackColors.stroke, lineWidth: 1)
                )
                .focused($focusedField, equals: .sessionName)

            Text(NSLocalizedString("session_name_hint", comment: ""))
                .font(.caption2)
                .foregroundColor(DesignTokens.UtilityColors.duplicateWarning)
        }
    }

    // MARK: - Descriptions

    @ViewBuilder
    func descriptionsSection() -> some View {
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

            if !duplicateIndices.isEmpty {
                Text(NSLocalizedString("duplicate_descriptions_detected", comment: "Duplicate descriptions detected"))
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.UtilityColors.duplicateWarning)
            }

            if showAddDescriptionField {
                addDescriptionField()
            }
        }
    }

    @ViewBuilder
    func emptyDescriptionsView() -> some View {
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
    func descriptionRow(description: String, index: Int) -> some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            TextField(NSLocalizedString("description_placeholder", comment: ""), text: Binding(
                get: { descriptions[safe: index] ?? "" },
                set: { newValue in
                    if index < descriptions.count {
                        descriptions[index] = newValue
                        if !duplicateIndices.isEmpty {
                            duplicateIndices = findDuplicateIndices(in: descriptions)
                        }
                    }
                }
            ))
            .textFieldStyle(PlainTextFieldStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DesignTokens.CosmosColors.cardBackground)
            .cornerRadius(DesignTokens.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(
                        duplicateIndices.contains(index)
                            ? DesignTokens.UtilityColors.duplicateWarning
                            : DesignTokens.BlackColors.stroke,
                        lineWidth: 1
                    )
            )
            .focused($focusedField, equals: .description(index))

            Button {
                descriptions.remove(at: index)
                if !duplicateIndices.isEmpty {
                    duplicateIndices = findDuplicateIndices(in: descriptions)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(DesignTokens.MoonColors.accentOrange)
                    .font(DesignTokens.Fonts.symbolMedium)
            }
        }
    }

    @ViewBuilder
    func addDescriptionField() -> some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            TextField(NSLocalizedString("new_description_placeholder", comment: ""), text: $newDescription)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DesignTokens.CosmosColors.cardBackground)
                .cornerRadius(DesignTokens.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(DesignTokens.BlackColors.stroke, lineWidth: 1)
                )
                .focused($focusedField, equals: .newDescription)

            Button {
                let trimmed = newDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    descriptions.append(trimmed)
                    newDescription = ""
                }
                if !duplicateIndices.isEmpty {
                    duplicateIndices = findDuplicateIndices(in: descriptions)
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

    func createSession() {
        let trimmedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = NSLocalizedString("error_empty_session_name", comment: "Session name cannot be empty")
            showError = true
            return
        }
        let duplicateHits = findDuplicateIndices(in: descriptions)
        guard duplicateHits.isEmpty else {
            duplicateIndices = duplicateHits
            return
        }
        duplicateIndices = []
        do {
            try sessionManager.addOrUpdateEntry(
                originalKey: "",
                sessionName: trimmedName,
                tasks: descriptions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            )
            dismiss()
        } catch {
            // Validation already surfaced through disablement; swallow remaining errors to avoid alerts.
        }
    }

    var isCreateDisabled: Bool {
        sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func findDuplicateIndices(in values: [String]) -> Set<Int> {
        var seen: [String: Int] = [:]
        var dups = Set<Int>()
        for (index, value) in values.enumerated() {
            let key = value.tsu_normalizedKey
            if key.isEmpty { continue }
            if let firstIndex = seen[key] {
                dups.insert(firstIndex)
                dups.insert(index)
            } else {
                seen[key] = index
            }
        }
        return dups
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
