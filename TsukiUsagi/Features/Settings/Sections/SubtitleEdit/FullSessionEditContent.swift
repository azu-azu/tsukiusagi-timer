//
//  FullSessionEditContent.swift
//  TsukiUsagi
//
//  セッション全体編集用コンテンツView
//  責務：
//    - セッション名の編集機能
//    - 複数Descriptionの編集機能
//    - フォーカス状態管理（セッション名 + Description間）
//    - Description追加・削除機能
//

import SwiftUI
import Foundation
import UIKit

/// Custom Session全体編集用のコンテンツView
///
/// セッション名とすべてのDescriptionを編集可能にする
struct FullSessionEditContent: View {
    @State private var sessionName: String
    @State private var drafts: [SessionEditSheetBuilder.DescriptionDraft]
    @State private var duplicateIDs: Set<UUID> = []
    @State private var duplicateDebouncer = Debouncer(delay: 0.15)
    let onSessionNameChange: (String) -> Void
    let onDescriptionsChange: ([SessionEditSheetBuilder.DescriptionDraft]) -> Void
    @Binding var isAnyFieldFocused: Bool
    let onClearFocus: () -> Void
    let onDuplicateStateChange: (Bool) -> Void
    let onFocusChange: (UUID?) -> Void

    @FocusState private var focusedField: FocusedField?

    private enum FocusedField: Hashable {
        case sessionName
        case description(UUID)
    }

    /// FullSessionEditContentの初期化
    /// - Parameters:
    ///   - sessionName: 初期のセッション名
    ///   - descriptionDrafts: 初期のDescriptionドラフト
    ///   - onSessionNameChange: セッション名変更時のコールバック
    ///   - onDescriptionsChange: Descriptionリスト変更時のコールバック
    ///   - isAnyFieldFocused: 外部から制御するフォーカス状態
    ///   - onClearFocus: フォーカスクリア時のコールバック
    init(
        sessionName: String,
        descriptionDrafts: [SessionEditSheetBuilder.DescriptionDraft],
        onSessionNameChange: @escaping (String) -> Void,
        onDescriptionsChange: @escaping ([SessionEditSheetBuilder.DescriptionDraft]) -> Void,
        isAnyFieldFocused: Binding<Bool>,
        onClearFocus: @escaping () -> Void,
        onDuplicateStateChange: @escaping (Bool) -> Void,
        onFocusChange: @escaping (UUID?) -> Void
    ) {
        _sessionName = State(initialValue: sessionName)
        _drafts = State(initialValue: descriptionDrafts)
        self.onSessionNameChange = onSessionNameChange
        self.onDescriptionsChange = onDescriptionsChange
        self._isAnyFieldFocused = isAnyFieldFocused
        self.onClearFocus = onClearFocus
        self.onDuplicateStateChange = onDuplicateStateChange
        self.onFocusChange = onFocusChange
    }

    var body: some View {
        VStack(spacing: 24) {
            sessionNameSection
            descriptionsSection
        }
        .onAppear {
            validateDuplicates()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                self.focusedField = .sessionName
            }
        }
        .onChange(of: drafts) { _, _ in
            duplicateDebouncer.schedule {
                validateDuplicates()
            }
        }
        .onChange(of: focusedField) { _, newValue in
            isAnyFieldFocused = newValue != nil
            switch newValue {
            case .description(let id):
                onFocusChange(id)
            default:
                onFocusChange(nil)
            }
        }
        .keyboardAwareBottomPadding(baseBottomPadding: DesignTokens.Padding.medium)
    }
}

private extension FullSessionEditContent {
    func clearFocus() {
        withAnimation {
            focusedField = nil
        }
        onClearFocus()
        onFocusChange(nil)
    }

    // MARK: - Private Views

    /// セッション名編集部分
    var sessionNameSection: some View {
        VStack(alignment: .leading) {
            Text("Session Name")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
            TextField("Enter session name", text: Binding(
                get: { [self] in self.sessionName },
                set: { [self] newValue in
                    self.sessionName = newValue
                    self.onSessionNameChange(newValue)
                }
            ))
            .textFieldStyle(PlainTextFieldStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DesignTokens.CosmosColors.cardBackground)
            .cornerRadius(DesignTokens.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(DesignTokens.BlackColors.stroke, lineWidth: 1)
            )
            .focused(self.$focusedField, equals: .sessionName)
        }
    }

    /// Descriptions編集部分
    var descriptionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Descriptions")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                // 追加ボタン
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
                    .focused(self.$focusedField, equals: .description(draft.id))
                    .submitLabel(draft.id == drafts.last?.id ? .done : .next)
                    .onSubmit {
                        if let nextID = nextID(after: draft.id) {
                            self.focusedField = .description(nextID)
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
            }

            // 入力ヒント
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            self.focusedField = .description(newDraft.id)
        }
    }

    func removeDescription(with id: UUID) {
        guard drafts.count > 1, let index = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts.remove(at: index)
        onDescriptionsChange(drafts)
        duplicateDebouncer.schedule {
            validateDuplicates()
        }

        // フォーカス調整
        if case .description(let focusedID) = focusedField, focusedID == id {
            if let replacement = drafts[safe: min(index, drafts.count - 1)]?.id {
                focusedField = .description(replacement)
            } else {
                focusedField = .sessionName
            }
        }
    }

    func validateDuplicates() {
        var seen: [String: UUID] = [:]
        var duplicates = Set<UUID>()

        let hadConflict = !duplicateIDs.isEmpty

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

        let hasConflict = !duplicates.isEmpty
        if hadConflict != hasConflict {
            let message = hasConflict
                ?
                NSLocalizedString(
                    "duplicate_descriptions_detected",
                    comment: "VoiceOver announcement when duplicates appear"
                )
                : NSLocalizedString(
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
