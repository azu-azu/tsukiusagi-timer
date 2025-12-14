//
//  FullSessionEditContent.swift
//  TsukiUsagi
//
//  セッション全体編集用コンテンツView
//  責務：
//    - セッション名の編集機能
//    - 複数Taskの編集機能
//    - フォーカス状態管理（セッション名 + Task間）
//    - Task追加・削除機能
//

import SwiftUI
import Foundation
import UIKit

/// Custom Session全体編集用のコンテンツView
///
/// セッション名とすべてのTaskを編集可能にする
/// Reflection方式の入力バーと連携（親コンポーネントが入力バーを管理）
struct FullSessionEditContent: View {
    /// 編集中のフィールドを表す
    enum EditingField: Equatable {
        case none
        case sessionName
        case task(id: UUID)
        case newTask
    }

    let sessionName: String
    let taskDrafts: [SessionEditSheetBuilder.TaskDraft]
    let duplicateIDs: Set<UUID>
    @Binding var editingField: EditingField
    let onSessionNameTap: () -> Void
    let onTaskTap: (UUID) -> Void
    let onNewTaskTap: () -> Void
    let onTaskDelete: (UUID) -> Void
    let isAddingNewTask: Bool

    var body: some View {
        VStack(spacing: 24) {
            sessionNameSection
            tasksSection
        }
    }
}

private extension FullSessionEditContent {
    // MARK: - Private Views

    /// セッション名編集部分
    var sessionNameSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text(Labels.InfoRow.sessionName)
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)

            EditablePlaceholderCard(
                text: sessionName,
                placeholder: LocalizedStringKey("enter_session_name_placeholder"),
                isEditing: editingField == .sessionName,
                onTap: onSessionNameTap
            )
        }
    }

    /// Tasks編集部分
    var tasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Labels.InfoRow.tasksOptional)
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                // 追加ボタン
                Button(action: onNewTaskTap) {
                    Image(systemName: "plus.circle.fill")
                        .font(DesignTokens.Fonts.symbolMedium)
                        .foregroundColor(DesignTokens.SkyToneColors.accentBlue)
                }
                .accessibilityLabel("Add task")
                .disabled(!duplicateIDs.isEmpty)
            }

            ForEach(taskDrafts) { draft in
                let isDuplicate = duplicateIDs.contains(draft.id)
                let isEditingThis = editingField == .task(id: draft.id)

                EditablePlaceholderCard(
                    text: draft.text,
                    placeholder: LocalizedStringKey("task_placeholder"),
                    isEditing: isEditingThis,
                    isDuplicate: isDuplicate,
                    onTap: { onTaskTap(draft.id) },
                    onDelete: taskDrafts.count > 1 ? { onTaskDelete(draft.id) } : nil
                )
            }

            // 新規タスク追加中のプレースホルダー
            if isAddingNewTask {
                EditablePlaceholderCard(
                    text: "",
                    placeholder: LocalizedStringKey("new_task_placeholder"),
                    isEditing: true,
                    onTap: {}
                )
            }

            // 重複警告
            if !duplicateIDs.isEmpty {
                Text(LocalizedStringKey("duplicate_tasks_detected"))
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.UtilityColors.duplicateWarning)
            }

            // 入力ヒント
            Text(LocalizedStringKey("settings_add_tasks_description"))
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                .padding(.top, 4)
        }
    }
}
