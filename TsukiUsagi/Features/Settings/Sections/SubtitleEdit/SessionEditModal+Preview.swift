//
//  SessionEditModal+Preview.swift
//  TsukiUsagi
//
//  SessionEditModal関連コンポーネントのプレビュー定義
//  責務：
//    - EditableModalのプレビュー
//    - DescriptionEditContentのプレビュー
//    - FullSessionEditContentのプレビュー
//    - デバッグ用サンプルデータ提供
//

import SwiftUI

#if DEBUG
struct SessionEditModal_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Description編集のプレビュー
            EditableModal(
                title: "Manage Descriptions",
                onSave: { print("Save tapped") },
                onCancel: { print("Cancel tapped") },
                isSaveDisabled: false,
                isKeyboardCloseVisible: false,
                onKeyboardClose: {},
                focusedRowID: .constant(nil),
                content: {
                    DescriptionEditContent(
                        sessionName: "Work",
                        descriptionDrafts: [
                            SessionEditSheetBuilder.DescriptionDraft(text: "SwiftUI development"),
                            SessionEditSheetBuilder.DescriptionDraft(text: "Code review")
                        ],
                        editingID: nil,
                        onDescriptionsChange: { drafts in
                            print("Descriptions changed: \(drafts.map(\.text))")
                        },
                        isAnyFieldFocused: .constant(false),
                        onClearFocus: {},
                        onDuplicateStateChange: { _ in },
                        onFocusChange: { _ in }
                    )
                }
            )
            .presentationDetents([.large])
            .previewDisplayName("Description Edit")

            // Full Session編集のプレビュー
            EditableModal(
                title: "Edit Session",
                onSave: { print("Save tapped") },
                onCancel: { print("Cancel tapped") },
                isSaveDisabled: false,
                isKeyboardCloseVisible: false,
                onKeyboardClose: {},
                focusedRowID: .constant(nil),
                content: {
                    FullSessionEditContent(
                        sessionName: "My Custom Project",
                        descriptionDrafts: [
                            SessionEditSheetBuilder.DescriptionDraft(text: "Task 1"),
                            SessionEditSheetBuilder.DescriptionDraft(text: "Task 2"),
                            SessionEditSheetBuilder.DescriptionDraft(text: "Task 3")
                        ],
                        onSessionNameChange: { newName in
                            print("Session name changed: \(newName)")
                        },
                        onDescriptionsChange: { drafts in
                            print("Descriptions changed: \(drafts.map(\.text))")
                        },
                        isAnyFieldFocused: .constant(false),
                        onClearFocus: {},
                        onDuplicateStateChange: { _ in },
                        onFocusChange: { _ in }
                    )
                }
            )
            .presentationDetents([.large])
            .previewDisplayName("Full Session Edit")

            // EditableModal単体のプレビュー
            EditableModal(
                title: "Sample Modal",
                onSave: { print("Save tapped") },
                onCancel: { print("Cancel tapped") },
                isSaveDisabled: false,
                isKeyboardCloseVisible: true,
                onKeyboardClose: { print("Keyboard close tapped") },
                focusedRowID: .constant(nil),
                content: {
                    VStack {
                        Text("Sample Content")
                            .font(DesignTokens.Fonts.title)
                            .padding()

                        Text("This is a demonstration of the reusable EditableModal component.")
                            .font(DesignTokens.Fonts.label)
                            .foregroundColor(DesignTokens.MoonColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            )
            .presentationDetents([.medium])
            .previewDisplayName("EditableModal Base")
        }
    }
}
#endif
