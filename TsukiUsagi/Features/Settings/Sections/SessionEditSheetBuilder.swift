import SwiftUI

/// セッション編集モーダル管理コンポーネント
///
/// 責務：
/// - Description編集とFull編集の切り替え
/// - キーボード表示状態の管理
/// - 編集完了・キャンセル処理の委譲
struct SessionEditSheetBuilder: View {
    let context: SessionEditContext
    @Binding var tempSessionName: String
    @Binding var tempDescriptions: [String]
    @Binding var isAnyFieldFocused: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

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
            onSave: onSave,
            onCancel: onCancel,
            isKeyboardCloseVisible: isAnyFieldFocused,
            onKeyboardClose: handleKeyboardClose,
            content: {
                DescriptionEditContent(
                    sessionName: context.sessionName,
                    descriptions: tempDescriptions,
                    editingIndex: context.descriptionIndex,
                    onDescriptionsChange: { newDescriptions in
                        tempDescriptions = newDescriptions
                    },
                    isAnyFieldFocused: $isAnyFieldFocused,
                    onClearFocus: {
                        isAnyFieldFocused = false
                    }
                )
            }
        )
        .presentationDetents([.large])
    }

    private var fullSessionEditModal: some View {
        EditableModal(
            title: "Edit Session",
            onSave: onSave,
            onCancel: onCancel,
            isKeyboardCloseVisible: isAnyFieldFocused,
            onKeyboardClose: handleKeyboardClose,
            content: {
                FullSessionEditContent(
                    sessionName: tempSessionName,
                    descriptions: tempDescriptions,
                    onSessionNameChange: { newName in
                        tempSessionName = newName
                    },
                    onDescriptionsChange: { newDescriptions in
                        tempDescriptions = newDescriptions
                    },
                    isAnyFieldFocused: $isAnyFieldFocused,
                    onClearFocus: {
                        isAnyFieldFocused = false
                    }
                )
            }
        )
        .presentationDetents([.large])
    }

    // MARK: - Helper Methods

    private func handleKeyboardClose() {
        KeyboardManager.hideKeyboard {
            isAnyFieldFocused = false
        }
    }
}
