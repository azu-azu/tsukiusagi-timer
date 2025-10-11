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
import UIKit

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
    @State private var duplicateDebouncer = Debouncer(delay: 0.15)

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
            duplicateDebouncer.schedule {
                validateDuplicates()
            }
        }
        .onChange(of: focusedField) { _, newValue in
            isAnyFieldFocused = newValue != nil
            onFocusChange(newValue)
        }
        // Manage Descriptions は余白リフトへ統一
        // .keyboardAwareBottomPadding(baseBottomPadding: DesignTokens.Padding.medium)
    }

}

private extension DescriptionEditContent {
    func clearFocus() {
        withAnimation {
            focusedField = nil
        }
        onClearFocus()
        onFocusChange(nil)
    }

    // MARK: - Private Views

    /// セッションカテゴリ表示部分（編集不可）
    var sessionCategorySection: some View {
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
    var descriptionsSection: some View {
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
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .foregroundColor(
                        isDuplicate
                            ? DesignTokens.UtilityColors.duplicateWarning
                            : DesignTokens.MoonColors.textPrimary
                    )
                    .background(DesignTokens.CosmosColors.cardBackground)
                    .cornerRadius(DesignTokens.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .stroke(
                                isDuplicate
                                    ? DesignTokens.UtilityColors.duplicateWarning
                                    : DesignTokens.BlackColors.stroke,
                                lineWidth: isDuplicate ? 2 : 1
                            )
                    )
                    .focused($focusedField, equals: draft.id)
                    .submitLabel(draft.id == drafts.last?.id ? .done : .next)
                    .onSubmit {
                        if let nextID = nextID(after: draft.id) {
                            focusedField = nextID
                        } else {
                            Keyboard.dismiss()
                            focusedField = nil
                        }
                    }

                    if drafts.count > 1 {
                        let index = drafts.firstIndex(where: { $0.id == draft.id }) ?? 0
                        Button(
                            action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                removeDescription(with: draft.id)
                            },
                            label: {
                                Image(systemName: "minus.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(DesignTokens.MoonColors.accentOrange)
                            }
                        )
                        .buttonStyle(.plain)
                        .padding(.leading, 4)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Remove description \(index + 1)")
                    }
                }
                .padding(.vertical, 4)
                .background(
                    GeometryReader { geo in
                        let isFocused = (focusedField == draft.id)
                        Color.clear.preference(
                            key: FocusedRowBottomPrefKey.self,
                            value: isFocused ? geo.frame(in: .named("DescScroll")).maxY : 0
                        )
                    }
                )
            }

            Text("Add descriptions for what you'll work on during this session")
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Helper Methods

    func binding(for id: UUID) -> Binding<String> {
        Binding(
            get: {
                drafts.first(where: { $0.id == id })?.text ?? ""
            },
            set: { newValue in
                guard let index = drafts.firstIndex(where: { $0.id == id }) else { return }
                drafts[index].text = newValue
                onDescriptionsChange(drafts)
                duplicateDebouncer.schedule {
                    validateDuplicates()
                }
            }
        )
    }

    func addDescription() {
        let newDraft = SessionEditSheetBuilder.DescriptionDraft(text: "")
        drafts.append(newDraft)
        onDescriptionsChange(drafts)
        duplicateDebouncer.schedule {
            validateDuplicates()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = newDraft.id
        }
    }

    func removeDescription(with id: UUID) {
        guard drafts.count > 1, let index = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts.remove(at: index)
        onDescriptionsChange(drafts)
        duplicateDebouncer.schedule {
            validateDuplicates()
        }

        if focusedField == id {
            if let next = drafts[safe: min(index, drafts.count - 1)]?.id {
                focusedField = next
            } else {
                focusedField = drafts.last?.id
            }
        }
    }

    func validateDuplicates() {
        var seen: [String: UUID] = [:]
        var duplicates = Set<UUID>()

        let hadConflict = !duplicateIDs.isEmpty

        for draft in drafts {
            let key = draft.text.tsu_taskNormalizedKey
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

        let hasConflict = !duplicates.isEmpty
        if hadConflict != hasConflict {
            let message = hasConflict
                ?
                NSLocalizedString(
                    "duplicate_descriptions_detected",
                    comment: "VoiceOver announcement when duplicates appear"
                )
                :
                NSLocalizedString(
                    "duplicate_descriptions_resolved",
                    comment: "VoiceOver announcement when duplicates are resolved"
                )
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    var hasDuplicateConflict: Bool {
        !duplicateIDs.isEmpty
    }

    func nextID(after id: UUID) -> UUID? {
        guard let index = drafts.firstIndex(where: { $0.id == id }) else { return nil }
        let nextIndex = drafts.index(after: index)
        return nextIndex < drafts.endIndex ? drafts[nextIndex].id : nil
    }
}
