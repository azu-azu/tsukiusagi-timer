//
//  SessionEditModal+Preview.swift
//  TsukiUsagi
//
//  SessionEditModal関連コンポーネントのプレビュー定義
//  責務：
//    - EditableModalのプレビュー
//    - TaskEditContentのプレビュー
//    - FullSessionEditContentのプレビュー
//    - デバッグ用サンプルデータ提供
//

import SwiftUI

#if DEBUG
struct SessionEditModal_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Task編集のプレビュー
            EditableModal(
                title: "Manage Tasks",
                onSave: { print("Save tapped") },
                onCancel: { print("Cancel tapped") },
                isSaveDisabled: false,
                isKeyboardCloseVisible: false,
                onKeyboardClose: {},
                focusedRowID: .constant(nil),
                content: {
                    TaskEditContent(
                        sessionName: "Work",
                        taskDrafts: [
                            SessionEditSheetBuilder.TaskDraft(text: "SwiftUI development"),
                            SessionEditSheetBuilder.TaskDraft(text: "Code review")
                        ],
                        editingID: nil,
                        onTasksChange: { drafts in
                            print("Tasks changed: \(drafts.map(\.text))")
                        },
                        isAnyFieldFocused: .constant(false),
                        onClearFocus: {},
                        onDuplicateStateChange: { _ in },
                        onFocusChange: { _ in }
                    )
                }
            )
            .presentationDetents([.large])
            .previewDisplayName("Task Edit")

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
                        taskDrafts: [
                            SessionEditSheetBuilder.TaskDraft(text: "Task 1"),
                            SessionEditSheetBuilder.TaskDraft(text: "Task 2"),
                            SessionEditSheetBuilder.TaskDraft(text: "Task 3")
                        ],
                        onSessionNameChange: { newName in
                            print("Session name changed: \(newName)")
                        },
                        onTasksChange: { drafts in
                            print("Tasks changed: \(drafts.map(\.text))")
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
                        Text(LocalizedStringKey("settings_sample_content"))
                            .font(DesignTokens.Fonts.title)
                            .padding()

                        Text(LocalizedStringKey("settings_demo_description"))
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
