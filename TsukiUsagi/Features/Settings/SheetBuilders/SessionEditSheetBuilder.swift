import SwiftUI
import Foundation

/// セッション編集モーダル管理コンポーネント
///
/// 責務：
/// - Description編集とFull編集の切り替え
/// - キーボード表示状態の管理
/// - 編集完了・キャンセル処理の委譲
struct SessionEditSheetBuilder: View {
    struct DescriptionDraft: Identifiable, Equatable {
        let id: UUID
        var text: String

        init(id: UUID = UUID(), text: String) {
            self.id = id
            self.text = text
        }
    }

    let context: SessionEditContext
    @Binding var tempSessionName: String
    @Binding var tempDescriptions: [String]
    @Binding var isAnyFieldFocused: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var hasDuplicateConflict = false
    @State private var descriptionDrafts: [DescriptionDraft] = []
    @State private var focusedRowID: UUID?

    private var initialSessionName: String { context.sessionName }
    private var initialDescriptions: [String] { context.tasks }

    private var hasChanges: Bool {
        if context.isDefaultSession {
            return descriptionDrafts.map(\.text) != initialDescriptions
        } else {
            return tempSessionName != initialSessionName || descriptionDrafts.map(\.text) != initialDescriptions
        }
    }

    private var isSaveDisabled: Bool {
        if hasDuplicateConflict { return true }
        if !hasChanges { return true }
        if !context.isDefaultSession {
            let trimmed = tempSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return true }
        }
        return false
    }

    var body: some View {
        switch context.editMode {
        case .descriptionOnly:
            descriptionEditModal
        case .fullSession:
            fullSessionEditModal
        }
    }

    // MARK: - Private Views

    private var descriptionEditModal: some View {
        EditableModal(
            title: "Manage Descriptions",
            onSave: {
                if !isSaveDisabled {
                    focusedRowID = nil
                    commitDrafts()
                    onSave()
                }
            },
            onCancel: {
                focusedRowID = nil
                resetDrafts()
                onCancel()
            },
            isSaveDisabled: isSaveDisabled,
            isKeyboardCloseVisible: isAnyFieldFocused,
            onKeyboardClose: handleKeyboardClose,
            focusedRowID: $focusedRowID,
            ensureVisibleMode: .bottomIfObscuredOnce,
            content: {
                DescriptionEditContent(
                    sessionName: context.sessionName,
                    descriptionDrafts: descriptionDrafts,
                    editingID: editingDraftID(),
                    onDescriptionsChange: { drafts in
                        descriptionDrafts = drafts
                        propagateDrafts()
                        hasDuplicateConflict = containsDuplicateDescriptions(drafts.map(\.text))
                    },
                    isAnyFieldFocused: $isAnyFieldFocused,
                    onClearFocus: {
                        isAnyFieldFocused = false
                    },
                    onDuplicateStateChange: { conflict in
                        hasDuplicateConflict = conflict
                    },
                    onFocusChange: { id in
                        focusedRowID = id
                    }
                )
                // フォーカス行の下端をモーダルへ伝える
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: FocusedRowBottomPrefKey.self,
                            value: geo.frame(in: .global).maxY
                        )
                    }
                )
            }
        )
        .presentationDetents([.large])
        .onAppear {
            resetDrafts()
            hasDuplicateConflict = containsDuplicateDescriptions(tempDescriptions)
            if let editingID = editingDraftID() {
                focusedRowID = editingID
            } else {
                focusedRowID = nil
            }
        }
    }

    private var fullSessionEditModal: some View {
        EditableModal(
            title: "Edit Session",
            onSave: {
                if !isSaveDisabled {
                    focusedRowID = nil
                    commitDrafts()
                    onSave()
                }
            },
            onCancel: {
                focusedRowID = nil
                resetDrafts()
                onCancel()
            },
            isSaveDisabled: isSaveDisabled,
            isKeyboardCloseVisible: isAnyFieldFocused,
            onKeyboardClose: handleKeyboardClose,
            focusedRowID: $focusedRowID,
            ensureVisibleMode: .centerAggressive,
            content: {
                FullSessionEditContent(
                    sessionName: tempSessionName,
                    descriptionDrafts: descriptionDrafts,
                    onSessionNameChange: { newName in
                        tempSessionName = newName
                    },
                    onDescriptionsChange: { drafts in
                        descriptionDrafts = drafts
                        propagateDrafts()
                        hasDuplicateConflict = containsDuplicateDescriptions(drafts.map(\.text))
                    },
                    isAnyFieldFocused: $isAnyFieldFocused,
                    onClearFocus: {
                        isAnyFieldFocused = false
                    },
                    onDuplicateStateChange: { conflict in
                        hasDuplicateConflict = conflict
                    },
                    onFocusChange: { id in
                        focusedRowID = id
                    }
                )
            }
        )
        .presentationDetents([.large])
        .onAppear {
            resetDrafts()
            hasDuplicateConflict = containsDuplicateDescriptions(tempDescriptions)
            focusedRowID = nil
        }
    }

    // MARK: - Helper Methods

    private func handleKeyboardClose() {
        isAnyFieldFocused = false
        focusedRowID = nil
        Task { @MainActor in
            Keyboard.dismiss()
        }
    }

    private func containsDuplicateDescriptions(_ descriptions: [String]) -> Bool {
        var seen = Set<String>()
        for value in descriptions {
            let key = value.tsu_taskNormalizedKey
            if key.isEmpty { continue }
            if seen.contains(key) {
                return true
            }
            seen.insert(key)
        }
        return false
    }

    private func resetDrafts() {
        let existing = descriptionDrafts
        descriptionDrafts = tempDescriptions.enumerated().map { index, text in
            if index < existing.count {
                return DescriptionDraft(id: existing[index].id, text: text)
            } else {
                return DescriptionDraft(text: text)
            }
        }
        propagateDrafts()
    }

    private func propagateDrafts() {
        tempDescriptions = descriptionDrafts.map(\.text)
    }

    private func commitDrafts() {
        propagateDrafts()
    }

    private func editingDraftID() -> UUID? {
        guard let index = context.descriptionIndex,
              index < descriptionDrafts.count else {
            return nil
        }
        return descriptionDrafts[index].id
    }
}
