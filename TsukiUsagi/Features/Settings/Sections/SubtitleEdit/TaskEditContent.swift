//
//  TaskEditContent.swift
//  TsukiUsagi
//
//  Task編集専用コンテンツView
//  責務：
//    - セッション名の固定表示（編集不可）
//    - 複数Taskの編集機能
//    - フォーカス状態管理
//    - Task追加・削除機能
//

import SwiftUI
import Foundation
import UIKit

/// Task編集専用のコンテンツView
///
/// セッション名の固定表示とTaskの編集フィールドを提供
/// Reflection方式の入力バーと連携（親コンポーネントが入力バーを管理）
struct TaskEditContent: View {
    let sessionName: String
    let taskDrafts: [SessionEditSheetBuilder.TaskDraft]
    let duplicateIDs: Set<UUID>
    let editingTaskID: UUID?
    let onTaskTap: (UUID) -> Void
    let onNewTaskTap: () -> Void
    let onTaskDelete: (UUID) -> Void
    let isAddingNewTask: Bool

    var body: some View {
        VStack(spacing: 24) {
            sessionCategorySection
            tasksSection
        }
    }
}

private extension TaskEditContent {
    // MARK: - Private Views

    /// セッション名表示部分（編集不可）
    var sessionCategorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Labels.InfoRow.sessionName)
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

    /// Tasks編集部分（複数対応）
    var tasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Labels.InfoRow.tasksOptional)
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                Button(action: onNewTaskTap) {
                    Image(systemName: "plus.circle.fill")
                        .font(DesignTokens.Fonts.symbolMedium)
                        .foregroundColor(DesignTokens.MoonColors.accentBlue)
                }
                .accessibilityLabel("Add task")
                .disabled(!duplicateIDs.isEmpty)
            }

            ForEach(taskDrafts) { draft in
                let isDuplicate = duplicateIDs.contains(draft.id)
                let isEditingThis = editingTaskID == draft.id

                SessionFieldPlaceholderCard(
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
                SessionFieldPlaceholderCard(
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

            Text(LocalizedStringKey("settings_add_tasks_description"))
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
                .padding(.top, 4)
        }
    }
}
