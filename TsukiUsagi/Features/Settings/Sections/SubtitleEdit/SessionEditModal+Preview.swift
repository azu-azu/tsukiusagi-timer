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
                isKeyboardCloseVisible: false,
                onKeyboardClose: {},
                content: {
                    DescriptionEditContent(
                        sessionName: "Work",
                        descriptions: ["SwiftUI development", "Code review"],
                        editingIndex: 0,
                        onDescriptionsChange: { newDescriptions in
                            print("Descriptions changed: \(newDescriptions)")
                        },
                        isAnyFieldFocused: .constant(false),
                        onClearFocus: {}
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
                isKeyboardCloseVisible: false,
                onKeyboardClose: {},
                content: {
                    FullSessionEditContent(
                        sessionName: "My Custom Project",
                        descriptions: ["Task 1", "Task 2", "Task 3"],
                        onSessionNameChange: { newName in
                            print("Session name changed: \(newName)")
                        },
                        onDescriptionsChange: { newDescriptions in
                            print("Descriptions changed: \(newDescriptions)")
                        },
                        isAnyFieldFocused: .constant(false),
                        onClearFocus: {}
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
                isKeyboardCloseVisible: true,
                onKeyboardClose: { print("Keyboard close tapped") },
                content: {
                    VStack {
                        Text("Sample Content")
                            .font(.title2)
                            .padding()

                        Text("This is a demonstration of the reusable EditableModal component.")
                            .font(.body)
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
