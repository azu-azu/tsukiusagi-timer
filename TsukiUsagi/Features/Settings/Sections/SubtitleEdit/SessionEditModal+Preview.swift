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
                        duplicateIDs: [],
                        editingTaskID: nil,
                        onTaskTap: { _ in print("Task tapped") },
                        onNewTaskTap: { print("New task tapped") },
                        onTaskDelete: { _ in print("Task deleted") },
                        isAddingNewTask: false
                    )
                }
            )
            .presentationDetents([.large])
            .previewDisplayName("Task Edit")

            // Full Session編集のプレビュー
            FullSessionEditPreviewWrapper()
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
                            .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
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

/// FullSessionEditContentのプレビュー用ラッパー（@Stateが必要なため）
private struct FullSessionEditPreviewWrapper: View {
    @State private var editingField: FullSessionEditContent.EditingField = .none

    var body: some View {
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
                    duplicateIDs: [],
                    editingField: $editingField,
                    onSessionNameTap: { print("Session name tapped") },
                    onTaskTap: { _ in print("Task tapped") },
                    onNewTaskTap: { print("New task tapped") },
                    onTaskDelete: { _ in print("Task deleted") },
                    isAddingNewTask: false
                )
            }
        )
    }
}
#endif
