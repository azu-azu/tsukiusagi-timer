//
//  DescriptionEditContent.swift
//  TsukiUsagi
//
//  Description編集専用コンテンツView
//  責務：
//    - セッション名の固定表示（編集不可）
//    - 複数Descriptionの編集機能
//    - フォーカス状態管理
//    - Description追加・削除機能
//

import SwiftUI
import Foundation

/// Description編集専用のコンテンツView
///
/// セッション名の固定表示とDescriptionの編集フィールドを提供
/// 視覚的に「何が固定で何が編集可能か」を明確に示す
struct DescriptionEditContent: View {
    let sessionName: String
    @State private var drafts: [SessionEditSheetBuilder.DescriptionDraft]
    let editingID: UUID?
    let onDescriptionsChange: ([SessionEditSheetBuilder.DescriptionDraft]) -> Void
    @Binding var isAnyFieldFocused: Bool
    let onClearFocus: () -> Void
    let onDuplicateStateChange: (Bool) -> Void
    let onFocusChange: (UUID?) -> Void

    @FocusState private var focusedField: UUID?
    @State private var duplicateIDs: Set<UUID> = []

    init(
        sessionName: String,
        descriptionDrafts: [SessionEditSheetBuilder.DescriptionDraft],
        editingID: UUID? = nil,
        onDescriptionsChange: @escaping ([SessionEditSheetBuilder.DescriptionDraft]) -> Void,
        isAnyFieldFocused: Binding<Bool>,
        onClearFocus: @escaping () -> Void,
        onDuplicateStateChange: @escaping (Bool) -> Void,
        onFocusChange: @escaping (UUID?) -> Void
    ) {
        self.sessionName = sessionName
        self.editingID = editingID
        _drafts = State(initialValue: descriptionDrafts)
        self.onDescriptionsChange = onDescriptionsChange
        self._isAnyFieldFocused = isAnyFieldFocused
        self.onClearFocus = onClearFocus
        self.onDuplicateStateChange = onDuplicateStateChange
        self.onFocusChange = onFocusChange
    }

    func clearFocus() {
        withAnimation {
            focusedField = nil
        }
        onClearFocus()
        onFocusChange(nil)
    }

    var body: some View {
        VStack(spacing: 24) {
            sessionCategorySection
            descriptionsSection
        }
        .onAppear {
            validateDuplicates()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let editingID {
                    focusedField = editingID
                    onFocusChange(editingID)
                } else if let lastID = drafts.last?.id {
                    focusedField = lastID
                    onFocusChange(lastID)
                }
            }
        }
        .onChange(of: drafts) { _, _ in
            validateDuplicates()
        }
        .onChange(of: focusedField) { _, newValue in
            isAnyFieldFocused = newValue != nil
            onFocusChange(newValue)
        }
        .keyboardAwareBottomPadding(baseBottomPadding: DesignTokens.Padding.medium)
    }

    // MARK: - Private Views

    /// セッションカテゴリ表示部分（編集不可）
    private var sessionCategorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Category")
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack {
                Text(sessionName)
                    .font(DesignTokens.Fonts.title)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                Spacer()

                Image(systemName: "lock.fill")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
                    .accessibilityLabel("Fixed category")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    /// Descriptions編集部分（複数対応）
    private var descriptionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Descriptions")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                Button(action: addDescription) {
                    Image(systemName: "plus.circle.fill")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.accentBlue)
                }
                .accessibilityLabel("Add description")
                .disabled(hasDuplicateConflict)
            }

            ForEach(drafts) { draft in
                HStack(alignment: .center, spacing: 12) {
                    let isDuplicate = duplicateIDs.contains(draft.id)

                    TextField(
                        "Description",
                        text: binding(for: draft.id)
                    )
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .foregroundColor(
                        isDuplicate
                            ? DesignTokens.MoonColors.accentOrange
                            : DesignTokens.MoonColors.textPrimary
                    )
                    .background(DesignTokens.CosmosColors.cardBackground)
                    .cornerRadius(DesignTokens.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .stroke(
                                isDuplicate
                                    ? DesignTokens.MoonColors.accentOrange
                                    : DesignTokens.BlackColors.stroke,
                                lineWidth: isDuplicate ? 2 : 1
                            )
                    )
                    .focused($focusedField, equals: draft.id)
                    .submitLabel(draft.id == drafts.last?.id ? .done : .next)
                    .onSubmit {
                        if let nextID = nextID(after: draft.id) {
                            focusedField = nextID
                        }
                    }

                    if drafts.count > 1 {
                        Button(
                            action: { removeDescription(with: draft.id) },
                            label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(DesignTokens.MoonColors.accentOrange)
                            }
                        )
                        .buttonStyle(.plain)
                        .padding(.trailing, 4)
                    }
                }
                .padding(.vertical, 4)
            }

            Text("Add descriptions for what you'll work on during this session")
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Helper Methods

    private func binding(for id: UUID) -> Binding<String> {
        Binding(
            get: {
                drafts.first(where: { $0.id == id })?.text ?? ""
            },
            set: { newValue in
                guard let index = drafts.firstIndex(where: { $0.id == id }) else { return }
                drafts[index].text = newValue
                validateDuplicates()
                onDescriptionsChange(drafts)
            }
        )
    }

    private func addDescription() {
        let newDraft = SessionEditSheetBuilder.DescriptionDraft(text: "")
        drafts.append(newDraft)
        validateDuplicates()
        onDescriptionsChange(drafts)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = newDraft.id
        }
    }

    private func removeDescription(with id: UUID) {
        guard drafts.count > 1, let index = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts.remove(at: index)
        validateDuplicates()
        onDescriptionsChange(drafts)

        if focusedField == id {
            if let next = drafts[safe: min(index, drafts.count - 1)]?.id {
                focusedField = next
            } else {
                focusedField = drafts.last?.id
            }
        }
    }

    private func validateDuplicates() {
        var seen: [String: UUID] = [:]
        var duplicates = Set<UUID>()

        for draft in drafts {
            let key = draft.text.tsu_descriptionNormalizedKey
            if key.isEmpty { continue }
            if let first = seen[key] {
                duplicates.insert(first)
                duplicates.insert(draft.id)
            } else {
                seen[key] = draft.id
            }
        }
        duplicateIDs = duplicates
        onDuplicateStateChange(!duplicates.isEmpty)
    }

    private var hasDuplicateConflict: Bool {
        !duplicateIDs.isEmpty
    }

    private func nextID(after id: UUID) -> UUID? {
        guard let index = drafts.firstIndex(where: { $0.id == id }) else { return nil }
        let nextIndex = drafts.index(after: index)
        return nextIndex < drafts.endIndex ? drafts[nextIndex].id : nil
    }
}
